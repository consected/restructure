# frozen_string_literal: true

# Tests for NfsStore::Manage::ContainerFile (base class for StoredFile and ArchivedFile)
#
# This spec covers:
# - File upload and StoredFile creation
# - Configuration handling for stored files
# - Embedded items based on nfs_store configuration
# - Regression tests for Issue #878 (implementation handler method guards)
# - Regression test for Issue #1303 (stale embedded_item memoization across before/after_create)
#
# The regression test (Issue #878) ensures that container files, which include
# Dynamic::ImplementationHandler, do not raise errors when calling methods like
# `default_option_type_name` that would otherwise call `definition` on classes
# that don't have it defined.
#
# The "uploads a file and creates a StoredFile with an embedded item" test guards against Issue
# #1303, where a stale per-instance memoization in Dynamic::ModelReferenceHandler#embedded_item
# could cache a nil result computed before the direct-embed link (embed_resource_id) was set,
# causing #embedded_item to keep returning nil even after the link was correctly persisted.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe NfsStore::Manage::ContainerFile, type: :model do
  include DynamicModelSupport
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  def upload_new_file
    f = 'dicoms.zip'
    zip_content = File.read(dicom_file_path(f))
    @zip_file = upload_file(f, zip_content)

    # expect(@uploaded_files.length).to be > 2
  end

  before :each do
    seed_database && ActivityLog.define_models

    setup_nfs_store
    generate_test_dynamic_model
    generate_test_embed_dynamic_models
    @activity_log = @container.parent_item

    # upload_test_dicom_files
  end

  it 'uploads a file and creates a StoredFile' do
    upload_new_file
    sf = @zip_file.stored_file

    expect(sf).to be_a NfsStore::Manage::StoredFile
    expect(sf.embedded_item).to be nil
  end

  it 'has a configuration for a stored file' do
    finalize_al_setup activity: :file_config
    expect(@activity_log.extra_log_type.to_s).to eq 'file_config'
    expect(@activity_log).to eq @container.parent_item
    upload_new_file
    sf = @zip_file.stored_file
    expect(sf).to be_a NfsStore::Manage::StoredFile
    expect(sf.option_type_config).to be_a OptionConfigs::ContainerFilesOptions

    af = sf.archived_files.first
    expect(af.option_type_config).to be nil

    finalize_al_setup activity: :file_config2
    upload_new_file
    sf = @zip_file.stored_file
    expect(sf).to be_a NfsStore::Manage::StoredFile
    expect(sf.option_type_config).to be_a OptionConfigs::ContainerFilesOptions

    af = sf.archived_files.first
    af.option_type_config
    expect(af.option_type_config).to be_a OptionConfigs::ContainerFilesOptions
  end

  it 'uploads a file and creates a StoredFile with an embedded item, based on nfs_store configuration' do
    setup_access :dynamic_model__test_embedded_recs
    setup_access :dynamic_model__test_created_by_recs

    finalize_al_setup activity: :file_config2
    upload_new_file
    sf = @zip_file.stored_file

    expect(sf).to be_a NfsStore::Manage::StoredFile
    expect(sf.option_type_config).to be_a OptionConfigs::ContainerFilesOptions
    expect(sf.embedded_item).to be_a DynamicModel::TestEmbeddedRec

    sf = sf.class.find(sf.id)
    sf.current_user = @user
    expect(sf.embedded_item).to be_a DynamicModel::TestEmbeddedRec

    # @todo - this will not work, because callbacks are not made when creating archived files
    # since we do everything in a mass insert for performance reasons. Limit to stored files only for now.
    #

    # af = sf.archived_files.first
    # expect(af).to be_a NfsStore::Manage::ArchivedFile
    # res = af.embedded_item
    # expect(res).to be_a DynamicModel::TestCreatedByRec
  end

  # Regression test for Issue #878
  # StoredFile and ArchivedFile include Dynamic::ImplementationHandler which has methods
  # that call `definition` without checking if the class responds to it.
  # This test ensures those methods don't raise errors when called on container files.
  it 'does not raise error when calling implementation handler methods on container files' do
    # These methods are in Dynamic::ImplementationHandler and should return nil for container files
    # since they don't have a definition (unlike DynamicModel or ActivityLog implementations)
    upload_new_file
    sf = @zip_file.stored_file

    # Instance method should return nil, not raise an error
    expect(sf.default_option_type_name).to be_nil

    # Class methods should also return nil, not raise an error
    expect(NfsStore::Manage::StoredFile.option_type_attr_name).to be_nil
    expect(NfsStore::Manage::StoredFile.default_option_type_name).to be_nil
    expect(NfsStore::Manage::ArchivedFile.option_type_attr_name).to be_nil
    expect(NfsStore::Manage::ArchivedFile.default_option_type_name).to be_nil

    # JSON serialization should work without errors (this was the original bug)
    expect { sf.as_json(limited_results: true) }.not_to raise_error
  end
end
