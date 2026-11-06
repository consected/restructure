# frozen_string_literal: true

# Covers batched config-library dependency refreshes during imports and unchanged refreshes outside imports.
require 'rails_helper'

RSpec.describe Admin::ConfigLibrary, type: :model do
  let(:admin) { Admin.new(id: 1) }
  let(:library_one) { described_class.new(format: 'yaml') }
  let(:library_two) { described_class.new(format: 'yaml', current_admin: admin) }
  let(:dependent) { DynamicModel.new(id: 42) }

  before do
    allow(ActivityLog).to receive(:active).and_return([])
    allow(DynamicModel).to receive(:active).and_return([dependent])
    allow(ExternalIdentifier).to receive(:active).and_return([])
    allow(OptionConfigs::ActivityLogOptions).to receive(:config_libraries)
    allow(OptionConfigs::DynamicModelOptions).to receive(:config_libraries)
      .with(dependent)
      .and_return([library_one, library_two])
    allow(OptionConfigs::ExternalIdentifierOptions).to receive(:config_libraries)
    allow(dependent).to receive_messages(uses_current_definition_version?: false, current_admin: nil)
    allow(dependent).to receive(:current_admin=)
    allow(dependent).to receive(:touch)
    allow(dependent).to receive(:force_option_config_parse)
    allow(DynamicModel).to receive(:reset_active_model_configurations!)
  end

  it 'refreshes a dependant once for multiple changed libraries during an import' do
    importer = double('app type importer')
    allow(Admin::AppTypeImport).to receive(:new).and_return(importer)
    allow(importer).to receive(:do_import_config) do
      library_one.send(:refresh_dependencies)
      library_two.send(:refresh_dependencies)
      expect(dependent).not_to have_received(:touch)
      [:imported]
    end

    Admin::AppTypeImport.import_config('config', admin)

    expect(dependent).to have_received(:touch).once
    expect(dependent).to have_received(:force_option_config_parse).once
    expect(dependent).to have_received(:current_admin=).with(admin).once
    expect(DynamicModel).to have_received(:reset_active_model_configurations!).once
    expect(OptionConfigs::DynamicModelOptions).to have_received(:config_libraries).with(dependent).once
  end

  it 'refreshes dependencies immediately outside an import' do
    library_one.send(:refresh_dependencies)

    expect(dependent).to have_received(:touch).once
    expect(dependent).to have_received(:force_option_config_parse).once
    expect(DynamicModel).to have_received(:reset_active_model_configurations!).once
  end
end
