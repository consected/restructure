# frozen_string_literal: true

#
# Handle server actions such as restarts and showing
# server settings to admins to assist with identifying issues
class Admin::ServerInfo
  NfsStoreSettingsVars = %w[
    nfs_store_directory
    temp_directory
    containers_dirname
    use_parent_sub_dir
    group_id_range
    configuration_successful
  ].freeze

  # Attempt to get the filename of the log from logger. If not, attempt to force it.
  LogFilename = Rails.logger.instance_variable_get('@logdev')&.filename&.to_s ||
                Rails.root.join('log', "#{Rails.env}.log").to_s

  attr_accessor :current_admin

  #
  # Get a hash of app settings from the *::Settings* class
  # @return [Hash]
  def app_settings
    settings = {}
    Settings::AppSettingsVars.each do |a|
      val = Settings.const_get(a)
    rescue StandardError => e
      val = e.to_s
    ensure
      settings[a] = val
    end

    settings
  end

  # Get a hash of app settings from the NfsStore::Manage::Filesystem class
  # @return [Hash]
  def nfs_store_settings
    settings = {}
    NfsStoreSettingsVars.each do |a|
      val = NfsStore::Manage::Filesystem.send(a)
    rescue StandardError => e
      val = e.to_s
    ensure
      settings[a] = val
    end

    settings
  end

  #
  # Get a hash of database settings based on the current database config
  # @return [Hash]
  def db_settings
    cx = ActiveRecord::Base.connection_db_config.configuration_hash.dup
    cx[:password] = '(hidden)'
    {
      current_database: Admin::MigrationGenerator.current_database,
      current_search_paths: Admin::MigrationGenerator.current_search_paths.join(', '),
      connection: cx
    }
  end

  #
  # Get the database server version
  # @return [String]
  def db_version
    result = ActiveRecord::Base.connection.execute('select version();')
    result.first['version']
  rescue StandardError => e
    "not available: #{e.message}"
  end

  #
  # Get memcached connection stats
  # @return [Hash]
  def memcached_stats
    unless Rails.cache.is_a?(ActiveSupport::Cache::MemCacheStore)
      return { status: 'not configured', details: 'Cache store is not Dalli' }
    end

    stats = Rails.cache.stats
    status =
      if stats.any?
        res = stats.find { |server, conn| conn.nil? }
        res ? 'connection failed' : 'connected'
      else
        'no server configured'
      end
    { status: status, servers: stats }
  rescue StandardError => e
    { status: 'connection failed', error: e.message }
  end

  def passenger_status
    IO.popen('passenger-status').read
  rescue StandardError
    'not available'
  end

  def passenger_memory_stats
    IO.popen('passenger-memory-stats').read
  rescue StandardError
    'not available'
  end

  def processes
    IO.popen('top -b -n 1 -o +%MEM -c -w 512').read
  rescue StandardError
    'not available'
  end

  def disk_usage
    IO.popen('df -h').read
  rescue StandardError
    'not available'
  end

  def instance_id
    IO.popen('ec2-metadata -i').read
  rescue StandardError
    res = IO.popen('hostname').read
    "hostname: #{res.strip}"
  rescue StandardError
    'server identifier not available'
  end

  def rails_log(regex, exclude: nil, max_count: 2000, tail_length: 10_000, trailing_context: 20)
    logfilename = LogFilename
    trailing_context = trailing_context.to_i

    if exclude.present?
      # Use awk with -v variables to safely pass patterns without injection risk
      # Context lines can contain the exclude pattern (per requirement: "must not filter the following context lines")
      awk_script = '{ lines[NR]=$0 } $0 ~ search && $0 !~ exclude { for(i=(NR-ctx<1?1:NR-ctx); i<NR; i++) if(lines[i]) print lines[i]; print; delete lines; count++; if(count>=max) exit }'
      cmds = [
        ['tail', '-n', tail_length.to_s, logfilename.to_s],
        ['tac'],
        ['awk', '-v', "search=#{regex}", '-v', "exclude=#{exclude}", '-v', "ctx=#{trailing_context}", '-v',
         "max=#{max_count}", awk_script],
        ['tac']
      ]
    else
      cmds = [
        ['tail', '-n', tail_length.to_s, logfilename.to_s],
        ['tac'],
        ['grep', '-m', max_count.to_s, "--before-context=#{trailing_context}", '-E', regex],
        ['tac']
      ]
    end

    pipe_chain = Utilities::ProcessPipes.new(cmds)
    pipe_chain.run
  rescue StandardError => e
    "log not available: #{e} - #{cmds}"
  end

  # NFS mount status constants
  NFS_STATUS_MOUNTED = :mounted
  NFS_STATUS_FAILED = :failed
  NFS_STATUS_ACCESSIBLE = :accessible
  NFS_STATUS_NOT_CONFIGURED = :not_configured
  NFS_STATUS_ERROR = :error

  # Check the source NFS filesystem mount status
  # @return [Hash] with keys :source_filesystem, :status
  def nfs_source_filesystem_status
    dir = NfsStore::Manage::Filesystem.nfs_store_directory
    group_id_range = NfsStore::Manage::Filesystem.group_id_range
    return { source_filesystem: nil, status: NFS_STATUS_NOT_CONFIGURED } unless dir.present? && group_id_range.any?

    mount_output = get_mount_output

    # Check the first gid directory to get source filesystem (they all share the same source)
    first_gid = group_id_range.first
    first_mount_path = File.join(dir, "gid#{first_gid}")

    # Check if any gid directory is mounted
    is_mounted = Pathname.new(first_mount_path).mountpoint?

    # Extract the source filesystem from the first gid mount
    source_filesystem = extract_source_filesystem(mount_output, first_mount_path)

    {
      source_filesystem: source_filesystem || '(not found)',
      status: is_mounted ? NFS_STATUS_MOUNTED : NFS_STATUS_FAILED
    }
  rescue StandardError => e
    Rails.logger.error "Error checking NFS source filesystem: #{e.message}"
    { source_filesystem: '(error)', status: NFS_STATUS_ERROR }
  end

  # Get NFS mount directory information for all group IDs
  # @return [Array<Hash>] array of mount information hashes
  def nfs_store_mount_dirs
    dir = NfsStore::Manage::Filesystem.nfs_store_directory
    group_id_range = NfsStore::Manage::Filesystem.group_id_range
    return [] unless dir.present?

    group_id_range.map do |gid|
      mount_path = File.join(dir, "gid#{gid}")
      pathname = Pathname.new(mount_path)

      {
        group_id: gid,
        mount_path: mount_path,
        mountpoint_status: pathname.mountpoint? ? NFS_STATUS_MOUNTED : NFS_STATUS_FAILED,
        directory_status: check_directory_accessible(mount_path)
      }
    end
  rescue StandardError => e
    Rails.logger.error "Error checking NFS mount dirs: #{e.message}"
    []
  end

  def configuration_successful
    configuration_failed_reason.blank?
  end

  def configuration_failed_reason
    return @configuration_failed_reason unless @configuration_failed_reason.nil?

    @configuration_failed_reason = []

    unless NfsStore::Manage::Filesystem.configuration_successful
      @configuration_failed_reason += NfsStore::Manage::Filesystem.configuration_failed_reason
    end

    @configuration_failed_reason += Settings.configuration_failed_reason unless Settings.configuration_successful?

    # Check NFS mountpoint status
    mount_dirs_info = nfs_store_mount_dirs
    if mount_dirs_info.is_a?(Array)
      mount_dirs_info.each do |mount_info|
        if mount_info[:mountpoint_status] == NFS_STATUS_FAILED
          @configuration_failed_reason << "NFS mountpoint #{mount_info[:mount_path]} (gid#{mount_info[:group_id]}) is not mounted. See NfsStore Settings for details."
        elsif mount_info[:directory_status] == NFS_STATUS_FAILED
          @configuration_failed_reason << "NFS directory #{mount_info[:mount_path]} (gid#{mount_info[:group_id]}) is not accessible. See NfsStore Settings for details."
        end
      end
    end

    @configuration_failed_reason
  end

  #
  # Initialize the class with a valid, active admin
  # @param [Admin] admin
  def initialize(admin)
    raise FphsException, 'Initialization with admin blank is not valid' unless admin
    raise FphsException, 'a valid admin is required' unless admin.is_a?(Admin) && admin.enabled?

    self.current_admin = admin
  end

  private

  # Get mount command output for extracting source filesystems
  # @return [String] output from mount command
  def get_mount_output
    `mount 2>/dev/null` || ''
  rescue StandardError => e
    Rails.logger.warn "Could not get mount output: #{e.message}"
    ''
  end

  # Check if a directory is accessible by attempting to list its entries
  # @param [String] path - the directory path to check
  # @return [Symbol] :accessible or :failed
  def check_directory_accessible(path)
    return NFS_STATUS_FAILED if path.blank?

    Dir.entries(path)
    NFS_STATUS_ACCESSIBLE
  rescue StandardError => e
    Rails.logger.warn "Directory not accessible #{path}: #{e.message}"
    NFS_STATUS_FAILED
  end

  # Extract the source filesystem path from mount command output
  # @param [String] mount_output - output from mount command
  # @param [String] mount_path - the mount point path to search for
  # @return [String, nil] the source filesystem path or nil if not found
  def extract_source_filesystem(mount_output, mount_path)
    return nil if mount_output.blank?

    # Look for line matching the mount_path
    # Example: /efs-prod/main on /mnt/fphsfs/gid600 type fuse (...)
    mount_output.each_line do |line|
      next unless line.include?(" on #{mount_path} ")

      # Extract the first part (source filesystem)
      source = line.split(' on ').first&.strip
      return source if source.present?
    end

    nil
  end
end
