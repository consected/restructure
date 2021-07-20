# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Scripted::ScriptHandler, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport
  include ScriptedJobSupport

  def setup_test_container
    seed_database && ::ActivityLog.define_models
    create_admin
    create_user
    @app_type = @user.app_type
    create_item
    setup_nfs_store
    setup_scripted_job
    setup_container_and_al activity: :scripted_test
    setup_default_filters activity: :scripted_test

    upload_test_dicom_files
    expect(@activity_log).not_to be nil
  end

  it 'fails to run a script that does not exist' do
    config = {
      script_filename: 'non_existent_test'
    }

    expect { NfsStore::Scripted::ScriptHandler.run_script nil, config }.to raise_error(FphsException, 'ScriptHandler script_filename not found')
  end

  it 'fails to run a script that has a slash in its script_filename' do
    config = {
      script_filename: 'bad/test'
    }

    expect { NfsStore::Scripted::ScriptHandler.run_script nil, config }.to raise_error(FphsException, 'ScriptHandler invalid script_filename')
  end

  it 'runs a script based on a configuration' do
    config = {
      script_filename: 'simple_test.sh'
    }

    sh = NfsStore::Scripted::ScriptHandler.new(config)
    exit_res = sh.run_script nil
    expect(exit_res).to be true
    expect(sh.result).to eq ['This will work']
  end

  it 'runs an R script based on a configuration' do
    res = system('which Rscript > /dev/null 2>&1')
    expect(res).to be_truthy

    config = {
      script_filename: 'sample-rscript.r',
      args: %w[/tmp/somefile]
    }

    sh = NfsStore::Scripted::ScriptHandler.new(config)
    exit_res = sh.run_script nil
    expect(exit_res).to be true
    expect(sh.result).to be_a Array
    expect(sh.result.length).to eq 2
  end

  it 'runs a script that fails with an exception' do
    config = {
      script_filename: 'simple_failing_test.sh'
    }

    expect { NfsStore::Scripted::ScriptHandler.run_script nil, config }.to raise_error(FphsException, 'run_script failed')
  end

  it 'runs a script that fails silently' do
    config = {
      script_filename: 'simple_failing_test.sh',
      fail_silently: true
    }

    res = NfsStore::Scripted::ScriptHandler.run_script nil, config
    expect(res).to be false
  end

  it 'runs a script that fails due to a timeout' do
    config = {
      script_filename: 'timeout_test.sh',
      timeout: 1
    }

    expect { NfsStore::Scripted::ScriptHandler.run_script nil, config }.to raise_error(FphsException, 'run_script failed')

    config = {
      script_filename: 'timeout_test.sh',
      timeout: 1,
      fail_silently: true
    }

    res = NfsStore::Scripted::ScriptHandler.run_script nil, config
    expect(res).to be false
  end

  it 'runs a script that doesn\'t fail due to a timeout' do
    config = {
      script_filename: 'timeout_test.sh',
      timeout: 5
    }

    res = NfsStore::Scripted::ScriptHandler.run_script nil, config
    expect(res).to be true
  end

  it 'runs a script with arguments' do
    config = {
      script_filename: 'arg_test.sh',
      args: %w[first second third]
    }

    sh = NfsStore::Scripted::ScriptHandler.new(config)
    exit_res = sh.run_script nil
    expect(exit_res).to be true
    expect(sh.result).to eq ['args first second third']
  end

  it 'runs a script with arguments, one of which is the container_file_path' do
    config = {
      script_filename: 'filepath_arg_test.sh',
      args: %w[first container_file_path third]
    }

    cf = double('NfsStore::Manage::ContainerFile', user: 1, user_id: 1, retrieval_path: '/a/madeup/path', current_user: nil, 'current_user=': nil)
    res = NfsStore::Scripted::ScriptHandler.run_script cf, config
    expect(res).to be true
  end

  it 'runs a script with arguments, one of which has substitutions' do
    config = {
      script_filename: 'substituted_arg_test.sh',
      args: [
        '1',
        'user-{{user_id}}',
        'third'
      ]
    }

    user_preference = double(attributes: {})
    user = double('User',
                  id: 1,
                  email: 'test@rspec',
                  user_preference: user_preference,
                  contact_info: nil,
                  app_type: nil,
                  'app_type=': nil,
                  app_type_id: nil,
                  'app_type_id=': nil,
                  attributes: {
                    id: 1,
                    email: 'test@rspec',
                    app_type_id: 1
                  })

    cf = double('NfsStore::Manage::ContainerFile',
                user: user,
                user_id: 1,
                retrieval_path: '/a/madeup/path',
                'current_user=': nil,
                current_user: user,
                attributes: {
                  master_id: -1,
                  user_id: 1,
                  file_path: '/a'
                })
    res = NfsStore::Scripted::ScriptHandler.run_script cf, config
    expect(res).to be true

    sh = NfsStore::Scripted::ScriptHandler.new(config)
    exit_res = sh.run_script cf
    expect(exit_res).to be true
    expect(sh.result).to eq ['second arg was user-1']
  end

  it 'it processes the file at container_file_path and returns a file to store in the same directory' do
    config = {
      script_filename: 'store_back_test.sh',
      args: %w[container_file_path],
      on_success: {
        store_files: {
          to_same_path_as_source: true
        }
      }
    }

    setup_test_container

    al = @activity_log
    c = al.container
    cf = c.stored_files.first
    sh = NfsStore::Scripted::ScriptHandler.new(config)
    exit_res = sh.run_script cf
    expect(exit_res).to be true
    expect(sh.result).to eq ['/tmp/rspec-test-script-handler/newfile1.txt',
                             '/tmp/rspec-test-script-handler/newfile2.txt']

    sf_names = c.stored_files.order(id: :asc).map(&:file_name)
    expect(sf_names).to include 'newfile1.txt'
    expect(sf_names.last).to eq 'newfile2.txt'
    path = c.stored_files.map(&:path).uniq
    expect(path.length).to eq 1
    expect(path.first).to be_blank

    fe = File.exist?(c.stored_files.last.retrieval_path)
    expect(fe).to be_truthy

    # Try a file in a different path
    cf = c.stored_files.select { |sf| sf.file_name.end_with? '.dcm' }[1]
    new_path = 'test_path'
    cf.move_to new_path
    sh = NfsStore::Scripted::ScriptHandler.new(config)

    expect(c.stored_files.where(path: new_path, file_name: 'newfile1.txt').first).to be nil

    exit_res = sh.run_script cf
    expect(exit_res).to be true
    expect(sh.result).to eq ['/tmp/rspec-test-script-handler/newfile1.txt',
                             '/tmp/rspec-test-script-handler/newfile2.txt']

    sf_names = c.stored_files.order(id: :desc).map(&:file_name)
    expect(sf_names).to include 'newfile1.txt'
    expect(sf_names.first).to eq 'newfile2.txt'
    sfs = c.stored_files.order(id: :desc)
    expect(sfs.first.path).to eq new_path

    fe = File.exist?(c.stored_files.last.retrieval_path)
    expect(fe).to be_truthy
  end
end
