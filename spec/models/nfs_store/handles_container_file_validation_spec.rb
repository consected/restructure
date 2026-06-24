# frozen_string_literal: true

# Defence-in-depth validations on NfsStore container file rows.
#
# Even with entry-point guards (clean_path, validate_file_name!), a row
# planted via direct SQL, a regressed migration or a compromised admin
# could still carry a traversal `path` or a multi-segment `file_name`.
# The model validations added to HandlesContainerFile reject any such
# row on its next `save`, so the bad value can never be persisted (or
# updated in place) again — closing the loop for persisted-row defence.
require 'rails_helper'

RSpec.describe 'NfsStore::HandlesContainerFile validations', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :each do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
    upload_file 'innocent.txt'
    @sf = @container.stored_files.where(file_name: 'innocent.txt').first
  end

  describe '#file_name validation' do
    it 'rejects path-separator in file_name on a persisted record' do
      @sf.file_name = 'subdir/evil.txt'
      expect(@sf).not_to be_valid
      expect(@sf.errors[:file_name]).to be_present
    end

    it 'rejects ".." in file_name on a persisted record' do
      @sf.file_name = '..'
      expect(@sf).not_to be_valid
      expect(@sf.errors[:file_name]).to be_present
    end

    it 'rejects NUL byte in file_name on a persisted record' do
      @sf.file_name = "evil\x00.txt"
      expect(@sf).not_to be_valid
      expect(@sf.errors[:file_name]).to be_present
    end

    it 'rejects control characters in file_name on a persisted record' do
      @sf.file_name = "evil\n.txt"
      expect(@sf).not_to be_valid
      expect(@sf.errors[:file_name]).to be_present
    end

    it 'accepts a benign single-segment file_name' do
      @sf.file_name = 'renamed-ok.txt'
      expect(@sf).to be_valid
    end
  end

  describe '#path validation' do
    describe 'before_validation :clean_path (unpersisted records)' do
      def build_candidate(path)
        sf = @container.stored_files.build(
          file_hash: SecureRandom.hex(16),
          file_name: 'candidate.txt',
          file_size: 32,
          content_type: 'text/plain',
          user_id: @sf.user_id,
          path: path
        )
        sf.current_user = @sf.user
        sf
      end

      it 'gracefully rejects a traversal path by attaching an error (instead of raising)' do
        rec = build_candidate('../../etc')
        expect(rec.save).to be_falsey
        expect(rec.errors[:path]).to be_present
      end

      it 'gracefully rejects an absolute path by attaching an error (instead of raising)' do
        rec = build_candidate('/etc/passwd')
        expect(rec.save).to be_falsey
        expect(rec.errors[:path]).to be_present
      end

      it 'gracefully rejects a NUL byte in path by attaching an error (instead of raising)' do
        rec = build_candidate("ok\x00/sub")
        expect(rec.save).to be_falsey
        expect(rec.errors[:path]).to be_present
      end
    end

    # `before_validation :clean_path` skips on persisted rows, and
    # `path_unchanged` blocks ordinary attribute mutation. To test the
    # model validator against a planted row, use a raw UPDATE.
    describe 'persisted records defence-in-depth' do
      def plant_path(value)
        # Raw UPDATE bypasses AR callbacks/validations — simulates a row
        # planted via direct SQL. Re-attach current_user after reload so
        # `force_write_user` (before_validation) doesn't raise on `valid?`.
        ActiveRecord::Base.connection.exec_update(
          "UPDATE #{@sf.class.table_name} SET path = $1 WHERE id = $2",
          'plant_path',
          [value, @sf.id]
        )
        @sf.reload
        @sf.current_user = @sf.user
      end

      it 'rejects a planted traversal path' do
        plant_path('../../etc')
        expect(@sf).not_to be_valid
        expect(@sf.errors[:path]).to be_present
      end

      it 'rejects a planted absolute path' do
        plant_path('/etc/passwd')
        expect(@sf).not_to be_valid
        expect(@sf.errors[:path]).to be_present
      end

      it 'cannot store a NUL byte in path (PostgreSQL text rejects it at the driver)' do
        expect { plant_path("ok\x00/sub") }.to raise_error(ArgumentError, /null byte/)
      end

      it 'accepts a planted benign multi-segment relative path' do
        plant_path('a/b/c')
        @sf.valid?
        expect(@sf.errors[:path]).to be_blank
      end

      it 'accepts a nil path' do
        plant_path(nil)
        @sf.valid?
        expect(@sf.errors[:path]).to be_blank
      end
    end
  end
end
