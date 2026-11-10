# frozen_string_literal: true

# Regression coverage for issue #1493: moving an archive base folder preserves its mount suffix.

require 'rails_helper'

RSpec.describe NfsStore::Archive::Mounter, type: :model do
  it 'adds the archive mount suffix when moving an archive base folder' do
    from_path = "old/archive.zip#{described_class::ArchiveMountSuffix}"
    to_path = 'new/archive.zip'
    file = instance_double(NfsStore::Manage::ArchivedFile, path: from_path)

    expect(file).to receive(:move_to).with("#{to_path}#{described_class::ArchiveMountSuffix}").and_return(true)

    expect(described_class.move_to_new_path(file, to_path)).to be true
  end

  it 'does not duplicate the archive mount suffix' do
    from_path = "old/archive.zip#{described_class::ArchiveMountSuffix}"
    to_path = "new/archive.zip#{described_class::ArchiveMountSuffix}"
    file = instance_double(NfsStore::Manage::ArchivedFile, path: from_path)

    expect(file).to receive(:move_to).with(to_path).and_return(true)

    expect(described_class.move_to_new_path(file, to_path)).to be true
  end
end
