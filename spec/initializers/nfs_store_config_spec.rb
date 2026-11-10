# frozen_string_literal: true

# Verify the NFS apps list written at boot gives app-scripts/set_up_missing_nfs_dirs.sh
# the containers path the app checks, so the script can confirm its setup is visible to the app,
# and that the list is replaced atomically so the script never reads a partly written list.
require 'rails_helper'

RSpec.describe 'NFS store configuration', type: :model do
  include ModelSupport

  let(:list_file) { Rails.root.join('tmp', 'agent-tmp', "nfs-apps-list-spec-#{Process.pid}.txt").to_s }

  before do
    @admin, = create_admin
    create_app_type(name: "nfs-list-#{SecureRandom.hex(4)}", label: 'NFS list spec')
    FileUtils.mkdir_p(File.dirname(list_file))
    stub_const('NFS_APPS_LIST_FILE', list_file)
  end

  after do
    FileUtils.rm_f(list_file)
  end

  it 'lists each active app type with the containers path the app checks' do
    ActiveSupport.run_load_hooks(:nfs_store_config, NfsStore::Manage::Filesystem)

    role_name = NfsStore::Manage::Group.valid_role_names.first
    expected_lines = Admin::AppType.active_app_types.map do |app_type|
      path = NfsStore::Manage::Filesystem.app_type_containers_path(app_type.id, role_name)
      "#{app_type.id} #{Dir.exist?(path)} test-fphsfs #{path}"
    end

    expect(expected_lines).not_to be_empty
    expect(File.readlines(list_file, chomp: true)).to eq(expected_lines)
  end

  it 'replaces the list only once it has been fully written' do
    File.write(list_file, "previous list\n")
    contents_during_write = []
    allow(NfsStore::Manage::Filesystem).to receive(:app_type_containers_path_exists?).and_wrap_original do |method, *args|
      contents_during_write << File.read(list_file)
      method.call(*args)
    end

    ActiveSupport.run_load_hooks(:nfs_store_config, NfsStore::Manage::Filesystem)

    expect(contents_during_write).not_to be_empty
    expect(contents_during_write.uniq).to eq(["previous list\n"])
    expect(File.read(list_file)).not_to eq("previous list\n")
    expect(Dir.glob("#{list_file}.*")).to be_empty
  end
end
