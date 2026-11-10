# frozen_string_literal: true

# Covers dependency refreshes only for meaningful config library changes, including multiple saves in one transaction.
require 'rails_helper'

RSpec.describe Admin::ConfigLibrary, type: :model do
  include ModelSupport

  let(:touches) { [] }
  let(:library) do
    described_class.new(
      current_admin: @admin,
      name: "refresh_test_#{SecureRandom.hex(4)}",
      category: "refresh_test_#{SecureRandom.hex(4)}",
      format: 'yaml',
      options: "setting: original\n"
    )
  end
  let(:dependent) { DynamicModel.new(id: 42) }

  before :all do
    create_admin
  end

  before do
    allow(ActivityLog).to receive(:active).and_return([])
    allow(DynamicModel).to receive(:active).and_return([dependent])
    allow(ExternalIdentifier).to receive(:active).and_return([])
    allow(OptionConfigs::ActivityLogOptions).to receive(:config_libraries)
    allow(OptionConfigs::DynamicModelOptions).to receive(:config_libraries)
      .with(dependent)
      .and_return([library])
    allow(OptionConfigs::ExternalIdentifierOptions).to receive(:config_libraries)
    allow(dependent).to receive_messages(uses_current_definition_version?: false, current_admin: nil)
    allow(dependent).to receive(:current_admin=)
    allow(dependent).to receive(:touch) { touches << :touched }
    allow(dependent).to receive(:force_option_config_parse)
    allow(DynamicModel).to receive(:reset_active_model_configurations!)
  end

  it 'does not refresh dependants when only updated_at changes' do
    library.save!
    touches.clear

    library.update!(updated_at: 1.second.from_now)

    expect(touches).to be_empty
  end

  it 'refreshes dependants immediately when options change outside an import' do
    library.save!
    touches.clear

    library.update!(options: "setting: changed\n")

    expect(touches).to eq([:touched])
  end

  it 'defers an options refresh until the import finishes' do
    library.save!
    touches.clear
    importer = double('app type importer')
    allow(Admin::AppTypeImport).to receive(:new).and_return(importer)
    allow(importer).to receive(:do_import_config) do
      described_class.transaction { library.update!(options: "setting: imported\n") }
      expect(touches).to be_empty
      [:imported]
    end

    Admin::AppTypeImport.import_config('config', @admin)

    expect(touches).to eq([:touched])
  end

  it 'refreshes after any content change saved earlier in the same transaction' do
    library.save!
    touches.clear

    described_class.transaction do
      library.update!(options: "setting: changed\n")
      library.update!(updated_at: 1.second.from_now)
    end

    expect(touches).to eq([:touched])
  end

  it 'refreshes when a content change and a timestamp-only save use different instances in one transaction' do
    library.save!
    touches.clear

    described_class.transaction do
      first_instance = described_class.find(library.id)
      first_instance.current_admin = @admin
      first_instance.update!(options: "setting: changed\n")

      last_instance = described_class.find(library.id)
      last_instance.current_admin = @admin
      last_instance.update!(updated_at: 1.second.from_now)
    end

    expect(touches).to eq([:touched])
  end

  it 'refreshes once after an import saves content and then a timestamp on different instances' do
    library.save!
    touches.clear
    importer = double('app type importer')
    allow(Admin::AppTypeImport).to receive(:new).and_return(importer)
    allow(importer).to receive(:do_import_config) do
      described_class.transaction do
        first_instance = described_class.find(library.id)
        first_instance.current_admin = @admin
        first_instance.update!(options: "setting: imported\n")

        last_instance = described_class.find(library.id)
        last_instance.current_admin = @admin
        last_instance.update!(updated_at: 1.second.from_now)
      end
      expect(touches).to be_empty
      [:imported]
    end

    Admin::AppTypeImport.import_config('config', @admin, force_update: :force)

    expect(touches).to eq([:touched])
  end

  it 'refreshes dependants when a new library is created' do
    library.save!

    expect(touches).to eq([:touched])
  end
end
