# frozen_string_literal: true

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
    seed_database && ::ActivityLog.define_models

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

    # @todo - this will not work, because callbacks are not made when creating archived files
    # since we do everything in a mass insert for performance reasons. Limit to stored files only for now.
    #

    # af = sf.archived_files.first
    # expect(af).to be_a NfsStore::Manage::ArchivedFile
    # res = af.embedded_item
    # expect(res).to be_a DynamicModel::TestCreatedByRec
  end
end
