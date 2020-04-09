# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Upload, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :all do
    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    # setup_nfs_store
    # @activity_log = @container.parent_item
  end

  before :each do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end

  it 'uploads in chunks' do
    c = @container

    u = NfsStore::Upload.new container: c, user: @container.master.current_user, file_name: 'test-name.txt'

    s1 = SecureRandom.hex
    ioupload = StringIO.new(s1)

    u.upload = ioupload
    u.chunk_count = 0

    res = u.send(:store_chunk)
    expect(res).to eq 1

    u.chunk_hash = Digest::MD5.hexdigest(s1)
    expect(u.send(:chunk_hash_match)).to be true

    s2 = SecureRandom.hex
    ioupload2 = StringIO.new(s2)

    u.upload = ioupload2
    res = u.send(:store_chunk)
    expect(res).to eq 2

    u.chunk_hash = Digest::MD5.hexdigest(s2)
    expect(u.send(:chunk_hash_match)).to be true

    u.send(:concat_chunks)

    final_file = File.read(u.send(:final_temp_path))

    totstring = s1 + s2
    expect(final_file).to eq(totstring)

    md5tot = Digest::MD5.hexdigest(totstring)
    expect(u.hash_for_file).to eq md5tot
  end

  it 'uploads a single large chunk efficiently' do
    c = @container

    u = NfsStore::Upload.new container: c, user: @container.master.current_user, file_name: 'test-name.txt'

    s1 = SecureRandom.hex
    ioupload = StringIO.new(s1)

    u.upload = ioupload
    u.chunk_count = 0

    res = u.send(:store_chunk)
    expect(res).to eq 1

    u.chunk_hash = Digest::MD5.hexdigest(s1)
    expect(u.send(:chunk_hash_match)).to be true

    u.send(:concat_chunks)

    final_file = File.read(u.send(:final_temp_path))

    totstring = s1
    expect(final_file).to eq(totstring)

    md5tot = Digest::MD5.hexdigest(totstring)
    expect(u.hash_for_file).to eq md5tot
  end

  it 'filters notifications' do
    if @container.respond_to? :filter_notifications

      role_name = 'upload test notify'

      files = []
      files << create_stored_file('.', 'not_abc_ is a test')
      files << create_stored_file('.', 'abc_ is a test')
      files << create_stored_file('.', 'abc_2 is a test')

      f0 = create_filter('^/abc_')
      f = create_filter('^/fabc')
      f = create_filter('^fdir\/')
      f = create_filter('^/fghi')
      f = create_filter('^fid\/{{id}} - id file')

      @container.previous_upload_stored_file_ids = files.map(&:id)

      res = @container.filter_notifications(@other_users + [@user])

      expect(res.length).to eq 1
      expect(res.first).to eq @user

      f0.disable!(@admin)

      res = @container.filter_notifications(@other_users + [@user])

      expect(res.length).to eq 0

      u0 = @other_users.first
      u1 = @other_users[1]

      f1 = create_filter('^/abc_', user: u0)
      f2 = create_filter('^/abc_', user: u1)

      res = @container.filter_notifications(@other_users + [@user])

      expect(res.length).to eq 2

      @user.user_roles.create! current_admin: @admin, role_name: role_name

      create_filter '^/abc_', role_name: role_name
      f1.disable!(@admin)

      res = @container.filter_notifications(@other_users + [@user])

      expect(res.length).to eq 2
      expect(res.last).to eq @user
      expect(res.first).to eq u1

      u1.user_roles.create! current_admin: @admin, role_name: role_name
      res = @container.filter_notifications(@other_users + [@user])

      expect(res.length).to eq 2
      expect(res.last).to eq @user
      expect(res.first).to eq u1
    end
  end
end
