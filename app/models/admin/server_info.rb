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
  ].freeze

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
    cx = ActiveRecord::Base.connection_config.dup
    cx[:password] = '(hidden)'
    {
      current_database: Admin::MigrationGenerator.current_database,
      current_search_paths: Admin::MigrationGenerator.current_search_paths.join(', '),
      connection: cx
    }
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

  def rails_log(regex, max_count: 2000, tail_length: 10_000, trailing_context: 20)
    logfilename = Rails.logger.instance_variable_get('@logdev')&.filename || 'none'
    trailing_context = trailing_context.to_i

    cmds = [
      ['tail', '-n', tail_length.to_s, logfilename],
      ['tac'],
      ['grep', '-m', max_count.to_s, "--before-context=#{trailing_context}", '-E', regex],
      ['tac']
    ]

    pipe_chain = Utilities::ProcessPipes.new(cmds)
    pipe_chain.run
  rescue StandardError => e
    "log not available: #{e} - #{cmds}"
  end

  def nfs_store_mount_dirs
    dir = NfsStore::Manage::Filesystem.nfs_store_directory
    group_id_range = NfsStore::Manage::Filesystem.group_id_range
    return unless dir.present?

    IO.popen("ls #{dir}/gid#{group_id_range.first}").read
  rescue StandardError
    'mount dirs not available'
  end

  #
  # Initialize the class with a valid, active admin
  # @param [Admin] admin
  def initialize(admin)
    raise FphsException, 'Initialization with admin blank is not valid' unless admin
    raise FphsException, 'a valid admin is required' unless admin.is_a?(Admin) && admin.enabled?

    self.current_admin = admin
  end
end
