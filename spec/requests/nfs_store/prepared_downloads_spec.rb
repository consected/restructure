# frozen_string_literal: true

# Purpose: ensure prepared archives are authenticated, scoped to their owner, and unavailable after expiry.
require 'rails_helper'

RSpec.describe 'NfsStore prepared downloads', type: :request do
  include ModelSupport

  let(:root) { Rails.root.join('tmp', "prepared-download-request-#{SecureRandom.hex}").to_s }
  let(:token) { SecureRandom.urlsafe_base64(32) }

  before do
    @user, = create_user
    sign_in @user
    @original_prepared_dir = ENV['FILESTORE_PREPARED_DOWNLOADS_DIR']
    ENV['FILESTORE_PREPARED_DOWNLOADS_DIR'] = root
  end

  after do
    ENV['FILESTORE_PREPARED_DOWNLOADS_DIR'] = @original_prepared_dir
    FileUtils.rm_rf(root)
  end

  def create_prepared_file(user, download_token, modified_at: Time.current)
    path = NfsStore::PreparedDownload.new.path_for(user_id: user.id, token: download_token)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, 'prepared zip bytes')
    File.utime(modified_at.to_time, modified_at.to_time, path)
    path
  end

  def get_prepared(download_token)
    get "/nfs_store/downloads/prepared/#{download_token}",
        params: { use_app_type: @user.app_type_id, no_redirect: 'true' }
  end

  it 'serves the requested user their valid archive' do
    create_prepared_file(@user, token)

    get_prepared(token)

    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Disposition']).to include('prepared-download.zip')
    expect(response.body).to eq('prepared zip bytes')
  end

  it 'switches to the linked app type without redirecting before serving the archive' do
    second_app_type = create_app_type(name: "prepared-download-#{SecureRandom.hex(4)}", label: 'Prepared download test')
    enable_user_app_access(second_app_type, @user)
    sign_in User.find(@user.id)
    create_prepared_file(@user, token)

    get "/nfs_store/downloads/prepared/#{token}",
        params: { use_app_type: second_app_type.id, no_redirect: 'true' }

    expect(response).to have_http_status(:ok)
    expect(response).not_to be_redirect
    expect(response.body).to eq('prepared zip bytes')
    expect(@user.reload.app_type_id).to eq(second_app_type.id)
  end

  it 'returns not found for another user, an expired file, and a malformed token' do
    other_user, = create_user
    create_prepared_file(other_user, token)
    get_prepared(token)
    expect(response).to have_http_status(:not_found)

    create_prepared_file(@user, token, modified_at: 2.days.ago)
    get_prepared(token)
    expect(response).to have_http_status(:not_found)

    get_prepared('../outside')
    expect(response).to have_http_status(:not_found)
  end

  describe 'show that Brakeman security warning is not an issue' do
    it 'rejects encoded traversal and malformed token shapes' do
      malformed_tokens = [
        '%2e%2e%2f%2e%2e%2fetc%2fpasswd',
        "#{'a' * 42}/",
        "#{'a' * 42}."
      ]

      malformed_tokens.each do |malformed_token|
        get "/nfs_store/downloads/prepared/#{malformed_token}",
            params: { use_app_type: @user.app_type_id, no_redirect: 'true' }
        expect(response).to have_http_status(:not_found), "Expected #{malformed_token.inspect} to be rejected"
      end
    end

    it 'does not serve a symlinked archive or follow a symlinked user directory' do
      prepared = NfsStore::PreparedDownload.new
      user_directory = File.dirname(prepared.path_for(user_id: @user.id, token:))
      outside_directory = Rails.root.join('tmp', "prepared-download-outside-#{SecureRandom.hex}").to_s
      outside_file = File.join(outside_directory, 'outside.zip')
      FileUtils.mkdir_p(outside_directory)
      File.write(outside_file, 'outside bytes')
      FileUtils.mkdir_p(user_directory)
      File.symlink(outside_file, prepared.path_for(user_id: @user.id, token:))

      get_prepared(token)
      expect(response).to have_http_status(:not_found)

      FileUtils.rm_rf(user_directory)
      outside_user_directory = File.join(outside_directory, 'user')
      FileUtils.mkdir_p(outside_user_directory)
      File.write(File.join(outside_user_directory, "#{token}.zip"), 'outside user bytes')
      File.symlink(outside_user_directory, user_directory)

      get_prepared(token)
      expect(response).to have_http_status(:not_found)
    ensure
      FileUtils.rm_rf(user_directory) if user_directory
      FileUtils.rm_rf(outside_directory) if outside_directory
    end
  end
end
