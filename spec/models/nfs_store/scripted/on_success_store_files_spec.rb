# frozen_string_literal: true

# Regression coverage for issue #1493: scripted results stored with an explicit destination path.

require 'rails_helper'

RSpec.describe NfsStore::Scripted::OnSuccessStoreFiles, type: :model do
  it 'uses each result filename when storing results to an explicit path' do
    result_path = '/tmp/script-result.txt'
    container = instance_double(NfsStore::Manage::Container)
    container_file = instance_double(
      NfsStore::Manage::StoredFile,
      container: container
    )
    script_handler = instance_double(NfsStore::Scripted::ScriptHandler, result: [result_path])

    expect(NfsStore::Manage::StoredFile).to receive(:store_new_file).with(
      result_path,
      container,
      { path: 'results', file_name: Pathname.new(result_path).basename }
    ).and_return(true)

    expect(
      described_class.perform(script_handler, container_file, to_path: 'results')
    ).to be true
  end
end
