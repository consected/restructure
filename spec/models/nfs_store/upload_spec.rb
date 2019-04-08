require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Upload, type: :model do

  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  DefaultRole = 'file1'

  before :all do
    setup_nfs_store
  end

  it "uploads in chunks" do

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

  it "uploads a single large chunk efficiently" do
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
end
