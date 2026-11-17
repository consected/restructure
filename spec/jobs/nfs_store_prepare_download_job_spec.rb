# frozen_string_literal: true

# Purpose: verify background archive creation preserves the request app type and notifies users on success or failure.
require 'rails_helper'

RSpec.describe NfsStorePrepareDownloadJob, type: :job do
  include ModelSupport

  let(:root) { Rails.root.join('tmp', "prepared-download-job-#{SecureRandom.hex}").to_s }
  let(:source_path) { File.join(root, 'source.txt') }
  let(:item) do
    { container_id: 1, parent_name: 'parent', container_name: 'container', container_path: '',
      file_name: 'source.txt', retrieval_path: source_path }
  end
  let(:download) { double(all_action_items: [item]) }
  let(:prepared_download) { NfsStore::PreparedDownload.new(root:) }
  let(:notification) { double(handle_notification_now: true) }

  before do
    @user, = create_user
    FileUtils.mkdir_p(root)
    File.write(source_path, 'download content')
    allow(NfsStore::PreparedDownload).to receive(:new).and_return(prepared_download)
    allow(Messaging::MessageNotification).to receive(:create!).and_return(notification)
    allow(notification).to receive(:handle_notification_now)
    allow(described_class).to receive(:notification_defaults).and_return(
      ready: { content: 'ready', layout: 'layout', subject: 'ready' },
      failed: { content: 'failed', layout: 'layout', subject: 'failed' }
    )
  end

  after { FileUtils.rm_rf(root) }

  def job_arguments(user, app_type_id: user.app_type_id)
    { user_id: user.id, app_type_id:, selected_items: [{ 'id' => 1, 'container_id' => 1,
                                                         'retrieval_type' => 'stored_file' }], container_id: nil, activity_log_type: nil,
      activity_log_id: nil, multi: true }
  end

  def stub_download
    allow(User).to receive(:find_by).and_return(@user)
    allow(@user).to receive(:app_type_valid?).and_return(true)
    allow(download).to receive(:current_user=)
    allow(download).to receive(:retrieve_files_from).and_return([item])
    allow(NfsStore::Download).to receive(:new).and_return(download)
  end

  it 'writes a zip and emails a link with the snapshotted app type without changing the saved user value' do
    stub_download
    saved_app_type_id = @user.app_type_id
    snapshot_app_type_id = saved_app_type_id + 100_000
    allow(@user).to receive(:app_type_valid?) do
      expect(@user.app_type_id).to eq(snapshot_app_type_id)
      true
    end

    described_class.perform_now(**job_arguments(@user, app_type_id: snapshot_app_type_id))

    archive_path = Dir.glob(File.join(root, @user.id.to_s, '*.zip')).first
    expect(archive_path).to be_present
    expect(File.stat(archive_path).mode & 0o777).to eq(0o640)
    expect(Zip::File.open(archive_path) { |zip| zip.read(zip.entries.first.name) }).to eq('download content')
    expect(@user.reload.app_type_id).to eq(saved_app_type_id)

    expect(Messaging::MessageNotification).to have_received(:create!).with(hash_including(
                                                                             content_template_name: 'ready', extra_substitutions_data: hash_including(
                                                                               download_link: include("use_app_type=#{snapshot_app_type_id}", 'no_redirect=true')
                                                                             )
                                                                           ))
    expect(notification).to have_received(:handle_notification_now)
  end

  it "formats the link expiry using the user's date/time and timezone preferences" do
    stub_download
    @user.user_preference.update!(timezone: 'Pacific Time (US & Canada)')

    described_class.perform_now(**job_arguments(@user))

    archive_path = Dir.glob(File.join(root, @user.id.to_s, '*.zip')).first
    expected_expiry = File.mtime(archive_path) + Settings::NfsStorePreparedDownloadsTtlHours.hours
    expected = Formatter::DateTime.format(expected_expiry, current_user: @user, show_timezone: true,
                                                           current_timezone: :user)
    expect(expected).to end_with('Pacific Time (US & Canada)')
    expect(Messaging::MessageNotification).to have_received(:create!)
      .with(hash_including(extra_substitutions_data: hash_including(expires_at: expected)))
  end

  it 'emails a failure and leaves no archive when access to the snapshotted app type was revoked' do
    allow(User).to receive(:find_by).and_return(@user)
    allow(@user).to receive(:app_type_valid?).and_return(false)

    described_class.perform_now(**job_arguments(@user))

    expect(Dir.glob(File.join(root, @user.id.to_s, '*.zip'))).to be_empty
    expect(Messaging::MessageNotification).to have_received(:create!).with(hash_including(content_template_name: 'failed'))
  end

  it 'removes a partial archive and sends failure notification when zipping fails' do
    stub_download
    allow(NfsStore::Archive::ZipFileGenerator).to receive(:zip_retrieved_items).and_raise(IOError, 'disk error')

    described_class.perform_now(**job_arguments(@user))

    expect(Dir.glob(File.join(root, @user.id.to_s, '*.zip'))).to be_empty
    expect(Messaging::MessageNotification).to have_received(:create!).with(hash_including(content_template_name: 'failed'))
  end

  it 'sends a failure notice when file access is revoked after enqueueing' do
    stub_download
    allow(download).to receive(:retrieve_files_from).and_raise(FsException::NoAccess, 'access revoked')

    described_class.perform_now(**job_arguments(@user))

    expect(Dir.glob(File.join(root, @user.id.to_s, '*.zip'))).to be_empty
    expect(Messaging::MessageNotification).to have_received(:create!).with(hash_including(content_template_name: 'failed'))
  end
end
