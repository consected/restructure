# frozen_string_literal: true

# Verify filestore setup failures are reported and pending work can be retried.
require 'spec_helper'
require 'fileutils'
require 'open3'
require 'pty'
require 'tmpdir'

RSpec.describe 'Filestore setup scripts' do
  let(:project_root) { File.expand_path('../..', __dir__) }
  let(:scripts_dir) { File.join(project_root, 'app-scripts') }
  let(:workspace) { @workspace }
  let(:bin_dir) { File.join(workspace, 'bin') }
  let(:mountpoint) { File.join(workspace, 'mountroot') }
  let(:sudo_log) { File.join(workspace, 'sudo.log') }
  let(:stat_log) { File.join(workspace, 'stat.log') }
  let(:restart_log) { File.join(workspace, 'restart.log') }
  let(:apps_list) { File.join(workspace, 'tmp', 'nfs_apps_list.txt') }
  let(:working_list) { "#{apps_list}.processing" }
  let(:environment) do
    {
      'PATH' => "#{bin_dir}:/usr/bin:/bin",
      'MOUNTPOINT' => mountpoint,
      'RAILS_ENV' => 'development',
      'SUBDIR' => '',
      'FS_DIR' => nil,
      'OWNER_GROUP' => 'review_group',
      'RESTART_REQUIRED' => nil,
      'UNCHANGED_EXIT_CODE' => nil,
      'BASH_ENV' => nil,
      'ENV' => nil,
      'CDPATH' => nil,
      'SHELLOPTS' => nil,
      'BASHOPTS' => nil,
      'MOCK_SUDO_LOG' => sudo_log,
      'MOCK_STAT_LOG' => stat_log,
      'MOCK_RESTART_LOG' => restart_log,
      'MOCK_FAIL_SUDO' => nil,
      'MOCK_FAIL_STAT' => nil,
      'MOCK_FAIL_MKDIR' => nil,
      'MOCK_FAIL_MV' => nil,
      'MOCK_NEW_LIST' => nil,
      'MOCK_NEW_LIST_PATH' => apps_list,
      'MOCK_HIDE_LIST' => nil,
      'MOCK_STAT_MATCH' => nil
    }
  end

  around do |example|
    temp_root = File.join(project_root, 'tmp', 'agent-tmp')
    FileUtils.mkdir_p(temp_root)
    Dir.mktmpdir('filestore-setup-spec-', temp_root) do |directory|
      @workspace = directory
      example.run
    end
  end

  before do
    FileUtils.mkdir_p([bin_dir, File.join(mountpoint, 'main')])
    write_stub('mkdir', <<~SH)
      #!/bin/sh
      if [ "$MOCK_FAIL_MKDIR" = yes ]; then
        echo 'simulated mkdir failure' >&2
        exit 1
      fi
      exec /bin/mkdir "$@"
    SH
    write_stub('stat', <<~'SH')
      #!/bin/sh
      printf '%s\n' "$3" >> "$MOCK_STAT_LOG"
      if [ "$3" = "$MOCK_FAIL_STAT" ]; then
        echo 'simulated stat failure' >&2
        exit 1
      fi
      if [ "$MOCK_STAT_MATCH" = yes ]; then
        case "$3" in
          */containers) echo '770-nfsuser:review_group' ;;
          *) echo '770-nfsuser:nfs_store_all_access' ;;
        esac
      else
        echo '755-test:test'
      fi
    SH
    write_stub('sudo', <<~'SH')
      #!/bin/sh
      printf '%s\n' "$*" >> "$MOCK_SUDO_LOG"
      # Simulate an app boot writing a newer list while the pipeline is running
      if [ -n "$MOCK_NEW_LIST" ] && [ ! -e "$MOCK_NEW_LIST_PATH" ]; then
        printf '%s' "$MOCK_NEW_LIST" > "$MOCK_NEW_LIST_PATH"
      fi
      if [ -n "$MOCK_FAIL_SUDO" ] && [ "$*" = "$MOCK_FAIL_SUDO" ]; then
        echo 'simulated sudo failure' >&2
        exit 1
      fi
      case "$1" in
        echo|chmod) "$@" ;;
        chown) exit 0 ;;
        *) echo "Unexpected sudo command: $*" >&2; exit 1 ;;
      esac
    SH
    write_stub('mount', <<~SH)
      #!/bin/sh
      if [ "$MOCK_HIDE_LIST" = yes ]; then
        /bin/mv tmp/nfs_apps_list.txt tmp/nfs_apps_list.txt.unavailable
      fi
      echo 'mountroot on /mnt/fphsfs/gid600 type fuse (rw)'
    SH
    write_stub('mv', <<~SH)
      #!/bin/sh
      for destination in "$@"; do :; done
      if [ -n "$MOCK_FAIL_MV" ] && [ "$destination" = "$MOCK_FAIL_MV" ]; then
        echo 'simulated mv failure' >&2
        exit 1
      fi
      exec /bin/mv "$@"
    SH
  end

  def write_stub(name, contents)
    path = File.join(bin_dir, name)
    File.write(path, contents)
    File.chmod(0o755, path)
  end

  def run_setup(extra_environment = {}, app_id: '71', input: '')
    arguments = [File.join(scripts_dir, 'setup_filestore_app.sh')]
    arguments << app_id if app_id
    Open3.capture3(environment.merge(extra_environment), '/bin/bash', *arguments, stdin_data: input)
  end

  def run_setup_on_terminal(extra_environment = {}, terminal_input: "unexpected-selection\n")
    PTY.open do |terminal, input|
      terminal.write(terminal_input)
      stdout_reader, stdout_writer = IO.pipe
      stderr_reader, stderr_writer = IO.pipe
      pid = Process.spawn(environment.merge(extra_environment), '/bin/bash',
                          File.join(scripts_dir, 'setup_filestore_app.sh'), '71',
                          in: input, out: stdout_writer, err: stderr_writer)
      stdout_writer.close
      stderr_writer.close
      _, status = Process.wait2(pid)
      [stdout_reader.read, stderr_reader.read, status]
    ensure
      [stdout_reader, stdout_writer, stderr_reader, stderr_writer].compact.each do |io|
        io.close unless io.closed?
      end
    end
  end

  def prepare_pipeline(contents)
    fixture_scripts = File.join(workspace, 'app-scripts')
    FileUtils.mkdir_p([fixture_scripts, File.dirname(apps_list), File.join(mountpoint, 'tenant', 'main')])
    FileUtils.cp(File.join(scripts_dir, 'setup_filestore_app.sh'), fixture_scripts)
    FileUtils.cp(File.join(scripts_dir, 'set_up_missing_nfs_dirs.sh'), fixture_scripts)
    File.chmod(0o755, File.join(fixture_scripts, 'setup_filestore_app.sh'))
    File.write(File.join(fixture_scripts, 'restart_app_server.sh'), <<~'SH')
      #!/bin/sh
      printf '%s\n' "$NO_SLEEP" >> "$MOCK_RESTART_LOG"
    SH
    File.chmod(0o755, File.join(fixture_scripts, 'restart_app_server.sh'))
    File.write(apps_list, contents)
  end

  def run_pipeline(rails_env, extra_environment = {})
    pipeline_environment = environment.merge(
      'RAILS_ENV' => rails_env,
      'MOUNTPOINT' => rails_env == 'production' ? nil : mountpoint
    ).merge(extra_environment)
    Open3.capture3(pipeline_environment, '/bin/bash', 'app-scripts/set_up_missing_nfs_dirs.sh', chdir: workspace)
  end

  describe 'setting up an app type' do
    commands = [
      'echo in: app-type-71/containers',
      'chmod 770 app-type-71',
      'chmod 770 app-type-71/containers',
      'chown nfsuser:nfs_store_all_access app-type-71',
      'chown nfsuser:review_group app-type-71/containers'
    ]

    commands.each_with_index do |command, index|
      it "reports and stops after privileged operation #{index + 1} fails" do
        _, stderr, status = run_setup({ 'MOCK_FAIL_SUDO' => command })

        expect(status).not_to be_success
        expect(stderr).to include('Failed to configure filestore permissions for app type 71')
        expect(File.readlines(sudo_log, chomp: true)).to eq(commands.first(index + 1))
      end
    end

    it 'reports directory creation failure before checking permissions' do
      _, stderr, status = run_setup({ 'MOCK_FAIL_MKDIR' => 'yes' })

      expect(status).not_to be_success
      expect(stderr).to include('Failed to create filestore directories for app type 71')
      expect(File).not_to exist(stat_log)
      expect(File).not_to exist(sudo_log)
    end

    ['app-type-71', 'app-type-71/containers'].each do |path|
      it "reports a failure to inspect #{path} without changing permissions" do
        _, stderr, status = run_setup({ 'MOCK_FAIL_STAT' => path })

        expect(status).not_to be_success
        expect(stderr).to include("Failed to inspect filestore permissions for #{path}")
        expect(File).not_to exist(sudo_log)
      end
    end

    it 'leaves existing contents intact when a permission command fails' do
      containers = File.join(mountpoint, 'main', 'app-type-71', 'containers')
      FileUtils.mkdir_p(containers)
      existing_file = File.join(containers, 'existing-data')
      File.write(existing_file, 'preserve')

      _, _, status = run_setup({ 'MOCK_FAIL_SUDO' => commands.last })

      expect(status).not_to be_success
      expect(File.read(existing_file)).to eq('preserve')
    end

    it 'rejects a missing app type ID without creating a directory' do
      _, stderr, status = run_setup({}, app_id: nil)

      expect(status).not_to be_success
      expect(stderr).to include('App type ID is required')
      expect(Dir.children(File.join(mountpoint, 'main'))).to be_empty
    end

    it 'accepts an app type ID provided through standard input' do
      _, stderr, status = run_setup({}, app_id: nil, input: "71\n")

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-71', 'containers'))
    end

    it 'does not invoke sudo when existing ownership and permissions match' do
      _, stderr, status = run_setup({ 'MOCK_STAT_MATCH' => 'yes' })

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).not_to exist(sudo_log)
    end

    describe 'reporting whether anything changed' do
      let(:containers) { File.join(mountpoint, 'main', 'app-type-71', 'containers') }

      it 'exits with UNCHANGED_EXIT_CODE when the directories and permissions already match' do
        FileUtils.mkdir_p(containers)

        stdout, stderr, status = run_setup({ 'MOCK_STAT_MATCH' => 'yes', 'UNCHANGED_EXIT_CODE' => '3' })

        expect(status.exitstatus).to eq(3)
        expect(stderr).to be_empty
        expect(stdout).to include('App type 71 filestore is already set up; nothing changed')
        expect(File).not_to exist(sudo_log)
      end

      it 'exits successfully when nothing changed and UNCHANGED_EXIT_CODE is not set' do
        FileUtils.mkdir_p(containers)

        _, stderr, status = run_setup({ 'MOCK_STAT_MATCH' => 'yes' })

        expect(status.exitstatus).to eq(0)
        expect(stderr).to be_empty
      end

      it 'exits successfully after creating the directories, even if permissions already match' do
        _, stderr, status = run_setup({ 'MOCK_STAT_MATCH' => 'yes', 'UNCHANGED_EXIT_CODE' => '3' })

        expect(status.exitstatus).to eq(0)
        expect(stderr).to be_empty
        expect(File).to be_directory(containers)
      end

      it 'exits successfully after correcting permissions on existing directories' do
        FileUtils.mkdir_p(containers)

        _, stderr, status = run_setup({ 'UNCHANGED_EXIT_CODE' => '3' })

        expect(status.exitstatus).to eq(0)
        expect(stderr).to be_empty
        expect(File).to exist(sudo_log)
      end

      ['0', '256', 'x', '-1'].each do |code|
        it "rejects an invalid UNCHANGED_EXIT_CODE #{code.inspect} before making changes" do
          _, stderr, status = run_setup({ 'UNCHANGED_EXIT_CODE' => code })

          expect(status.exitstatus).to eq(1)
          expect(stderr).to include('UNCHANGED_EXIT_CODE must be an integer from 1 to 255')
          expect(Dir.children(File.join(mountpoint, 'main'))).to be_empty
        end
      end
    end

    it 'uses the default container owner group when none is configured' do
      _, stderr, status = run_setup({ 'OWNER_GROUP' => nil })

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File.readlines(sudo_log, chomp: true)).to include(
        'chown nfsuser:nfs_store_group_0 app-type-71/containers'
      )
    end

    ['', 'tenant', 'tenant with spaces'].each do |subdir|
      it "sets up a valid app type with SUBDIR #{subdir.inspect}" do
        FileUtils.mkdir_p(File.join(mountpoint, subdir, 'main'))

        _, stderr, status = run_setup({ 'SUBDIR' => subdir })

        expect(status).to be_success
        expect(stderr).to be_empty
        containers = File.join(mountpoint, subdir, 'main', 'app-type-71', 'containers')
        expect(File).to be_directory(containers)
        expect(File.stat(containers).mode & 0o777).to eq(0o770)
      end
    end

    it 'uses the mount root when main is absent, ignoring an inherited FS_DIR' do
      Dir.rmdir(File.join(mountpoint, 'main'))

      _, stderr, status = run_setup({ 'FS_DIR' => 'stale-directory' })

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).to be_directory(File.join(mountpoint, 'app-type-71', 'containers'))
    end

    it 'handles the default development mount path when it contains spaces' do
      base = File.join(workspace, 'base with spaces')
      target = File.join(base, 'dev-filestore', 'main')
      FileUtils.mkdir_p(target)
      username = "filestore-spec-#{Process.pid} with spaces"
      expect(File).not_to exist(File.join('/media', username, 'Data'))
      settings = { 'MOUNTPOINT' => nil, 'FS_TEST_BASE' => base, 'USER' => username }

      _, stderr, status = run_setup(settings)

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).to be_directory(File.join(target, 'app-type-71', 'containers'))
    end

    it 'leaves piped input untouched when SUBDIR is unset' do
      command = <<~'SH'
        "$1" "$2"
        result=$?
        IFS= read -r remaining
        printf 'remaining: %s\n' "$remaining"
        exit "$result"
      SH
      stdout, stderr, status = Open3.capture3(environment.merge('SUBDIR' => nil), '/bin/bash', '-c', command,
                                              'test', File.join(scripts_dir, 'setup_filestore_app.sh'), '71',
                                              stdin_data: "next list row\n")

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout).to include("remaining: next list row\n")
    end

    it 'honors an explicitly empty SUBDIR on a terminal' do
      FileUtils.mkdir_p(File.join(mountpoint, 'unexpected-selection'))

      _, stderr, status = run_setup_on_terminal

      expect(status).to be_success
      expect(stderr).not_to include('Enter the selected directory:')
      expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-71', 'containers'))
      expect(File).not_to exist(File.join(mountpoint, 'unexpected-selection', 'app-type-71'))
    end

    it 'accepts an interactive selection when SUBDIR is unset' do
      FileUtils.mkdir_p(File.join(mountpoint, 'chosen', 'main'))

      _, stderr, status = run_setup_on_terminal({ 'SUBDIR' => nil }, terminal_input: "chosen\n")

      expect(status).to be_success
      expect(stderr).to include('Enter the selected directory:')
      expect(File).to be_directory(File.join(mountpoint, 'chosen', 'main', 'app-type-71', 'containers'))
    end

    it 'reports an aborted subdirectory prompt without creating an app directory' do
      _, stderr, status = run_setup_on_terminal({ 'SUBDIR' => nil }, terminal_input: "\x04")

      expect(status).not_to be_success
      expect(stderr).to include('Failed to read the filestore subdirectory')
      expect(Dir.children(File.join(mountpoint, 'main'))).to be_empty
    end
  end

  describe 'processing the pending app list' do
    list_contents = "201 false \n202 false tenant\n203 false \n204 true \n"

    %w[development production].each do |rails_env|
      it "retains the list without restarting after a #{rails_env} failure, then retries it" do
        prepare_pipeline(list_contents)
        failure = 'chown nfsuser:review_group app-type-202/containers'

        _, stderr, status = run_pipeline(rails_env, 'MOCK_FAIL_SUDO' => failure)

        expect(status).not_to be_success
        expect(stderr).to include('Failed to set up app type 202')
        expect(File.read(apps_list)).to eq(list_contents)
        expect(File).not_to exist("#{apps_list}.bak")
        expect(File).not_to exist(restart_log)
        expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-201', 'containers'))
        expect(File).to be_directory(File.join(mountpoint, 'tenant', 'main', 'app-type-202', 'containers'))
        expect(File).not_to exist(File.join(mountpoint, 'main', 'app-type-203'))

        _, retry_stderr, retry_status = run_pipeline(rails_env)

        expect(retry_status).to be_success
        expect(retry_stderr).to be_empty
        expect(File).not_to exist(apps_list)
        expect(File.read("#{apps_list}.bak")).to eq(list_contents)
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
        expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-203', 'containers'))
        expect(File).not_to exist(File.join(mountpoint, 'main', 'app-type-204'))
      end
    end

    it 'retains the list and avoids restarting if it cannot be archived' do
      prepare_pipeline("201 false \n")

      _, stderr, status = run_pipeline('development', 'MOCK_FAIL_MV' => 'tmp/nfs_apps_list.txt.bak')

      expect(status).not_to be_success
      expect(stderr).to include('Failed to archive the NFS app list')
      expect(File.read(apps_list)).to eq("201 false \n")
      expect(File).not_to exist(working_list)
      expect(File).not_to exist(restart_log)

      _, retry_stderr, retry_status = run_pipeline('development')

      expect(retry_status).to be_success
      expect(retry_stderr).to be_empty
      expect(File).to exist("#{apps_list}.bak")
      expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
    end

    it 'does not archive or restart if the pending list cannot be claimed' do
      contents = "201 false \n"
      prepare_pipeline(contents)

      _, stderr, status = run_pipeline('production', 'MOCK_HIDE_LIST' => 'yes')

      expect(status).not_to be_success
      expect(stderr).to include('Failed to claim the NFS app list')
      expect(File.read("#{apps_list}.unavailable")).to eq(contents)
      expect(File).not_to exist("#{apps_list}.bak")
      expect(File).not_to exist(restart_log)
    end

    it 'keeps an existing backup unchanged when setup fails' do
      contents = "201 false \n"
      prepare_pipeline(contents)
      File.write("#{apps_list}.bak", 'previous backup')

      _, _, status = run_pipeline('development',
                                  'MOCK_FAIL_SUDO' => 'chmod 770 app-type-201/containers')

      expect(status).not_to be_success
      expect(File.read(apps_list)).to eq(contents)
      expect(File.read("#{apps_list}.bak")).to eq('previous backup')
      expect(File).not_to exist(restart_log)
    end

    it 'archives an empty list without restarting' do
      prepare_pipeline('')

      _, stderr, status = run_pipeline('development')

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File.read("#{apps_list}.bak")).to be_empty
      expect(File).not_to exist(restart_log)
    end

    it 'processes a final pending entry without a trailing newline' do
      contents = '201 false'
      prepare_pipeline(contents)

      _, stderr, status = run_pipeline('development')

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-201', 'containers'))
      expect(File.read("#{apps_list}.bak")).to eq(contents)
      expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
    end

    it 'archives a list with no missing app types without restarting' do
      prepare_pipeline("201 true \n")

      _, stderr, status = run_pipeline('development')

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(File).not_to exist(apps_list)
      expect(File).to exist("#{apps_list}.bak")
      expect(File).not_to exist(restart_log)
    end

    %w[true false].each do |inherited_value|
      it "ignores an inherited RESTART_REQUIRED=#{inherited_value} when no app types are missing" do
        prepare_pipeline("201 true \n")

        _, stderr, status = run_pipeline('development', { 'RESTART_REQUIRED' => inherited_value })

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).to exist("#{apps_list}.bak")
        expect(File).not_to exist(restart_log)
      end
    end

    describe 'with the containers path the app checks' do
      def app_path(*parts)
        File.join(mountpoint, *parts, 'app-type-201', 'containers')
      end

      it 'restarts after creating directories at the path the app checks' do
        prepare_pipeline("201 false  #{app_path('main')}\n")

        _, stderr, status = run_pipeline('development')

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).to be_directory(app_path('main'))
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
      end

      it 'reads an app path containing spaces' do
        spaced_mountpoint = File.join(workspace, 'mount with spaces')
        spaced_path = File.join(spaced_mountpoint, 'main', 'app-type-201', 'containers')
        FileUtils.mkdir_p(File.join(spaced_mountpoint, 'main'))
        prepare_pipeline("201 false  #{spaced_path}\n")

        _, stderr, status = run_pipeline('development', { 'MOUNTPOINT' => spaced_mountpoint })

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).to be_directory(spaced_path)
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
      end

      it 'archives the list without restarting when pending app types were already set up' do
        FileUtils.mkdir_p(app_path('main'))
        contents = "201 false  #{app_path('main')}\n"
        prepare_pipeline(contents)

        stdout, stderr, status = run_pipeline('development', { 'MOCK_STAT_MATCH' => 'yes' })

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(stdout).to include('App type 201 filestore is already set up; nothing changed')
        expect(File).not_to exist(sudo_log)
        expect(File.read("#{apps_list}.bak")).to eq(contents)
        expect(File).not_to exist(restart_log)
      end

      it 'restarts once when one app type changed and another was already set up' do
        FileUtils.mkdir_p(app_path('main'))
        other_path = File.join(mountpoint, 'main', 'app-type-202', 'containers')
        prepare_pipeline("201 false  #{app_path('main')}\n202 false  #{other_path}\n")

        _, stderr, status = run_pipeline('development', { 'MOCK_STAT_MATCH' => 'yes' })

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).to be_directory(other_path)
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
      end

      { 'creates directories' => {}, 'finds nothing to change' => { 'MOCK_STAT_MATCH' => 'yes' } }
        .each do |description, settings|
        it "retains the list without restarting when setup #{description} but the app path is missing" do
          FileUtils.mkdir_p(app_path('main')) if settings.any?
          missing_path = app_path('elsewhere')
          contents = "201 false  #{missing_path}\n"
          prepare_pipeline(contents)

          _, stderr, status = run_pipeline('development', settings)

          expect(status).not_to be_success
          expect(stderr).to include(
            "App type 201 was set up, but the app's containers path #{missing_path} does not exist"
          )
          expect(File.read(apps_list)).to eq(contents)
          expect(File).not_to exist("#{apps_list}.bak")
          expect(File).not_to exist(restart_log)
        end
      end
    end

    describe 'when the app rewrites the list during a run' do
      let(:newer_list) { "301 false \n" }

      it 'archives only the list it processed and leaves the newer list for the next run' do
        contents = "201 false \n"
        prepare_pipeline(contents)

        _, stderr, status = run_pipeline('development', { 'MOCK_NEW_LIST' => newer_list })

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File.read("#{apps_list}.bak")).to eq(contents)
        expect(File.read(apps_list)).to eq(newer_list)
        expect(File).not_to exist(working_list)
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])

        _, next_stderr, next_status = run_pipeline('development')

        expect(next_status).to be_success
        expect(next_stderr).to be_empty
        expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-301', 'containers'))
        expect(File.read("#{apps_list}.bak")).to eq(newer_list)
      end

      it 'keeps the newer list rather than restoring the failed one' do
        prepare_pipeline("201 false \n")
        failure = 'chown nfsuser:review_group app-type-201/containers'

        _, stderr, status = run_pipeline('development', { 'MOCK_NEW_LIST' => newer_list, 'MOCK_FAIL_SUDO' => failure })

        expect(status).not_to be_success
        expect(stderr).to include('Failed to set up app type 201')
        expect(File.read(apps_list)).to eq(newer_list)
        expect(File).not_to exist(working_list)
        expect(File).not_to exist("#{apps_list}.bak")
        expect(File).not_to exist(restart_log)
      end
    end

    describe 'after an interrupted run' do
      it 'recovers a claimed list when no newer list exists' do
        prepare_pipeline('')
        File.delete(apps_list)
        File.write(working_list, "201 false \n")

        _, stderr, status = run_pipeline('development')

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).not_to exist(working_list)
        expect(File.read("#{apps_list}.bak")).to eq("201 false \n")
        expect(File.readlines(restart_log, chomp: true)).to eq(['true'])
      end

      it 'discards a claimed list when a newer list exists' do
        prepare_pipeline("202 false \n")
        File.write(working_list, "201 false \n")

        _, stderr, status = run_pipeline('development')

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(File).not_to exist(working_list)
        expect(File.read("#{apps_list}.bak")).to eq("202 false \n")
        expect(File).not_to exist(File.join(mountpoint, 'main', 'app-type-201'))
        expect(File).to be_directory(File.join(mountpoint, 'main', 'app-type-202', 'containers'))
      end
    end

    it 'leaves the list alone while another run holds the lock' do
      contents = "201 false \n"
      prepare_pipeline(contents)

      File.open(File.join(workspace, 'tmp', 'nfs_apps_list.lock'), File::RDWR | File::CREAT) do |lock|
        lock.flock(File::LOCK_EX)

        stdout, stderr, status = run_pipeline('development')

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(stdout).to include('Another NFS app list run is in progress')
      end

      expect(File.read(apps_list)).to eq(contents)
      expect(File).not_to exist(working_list)
      expect(File).not_to exist(restart_log)
    end
  end
end
