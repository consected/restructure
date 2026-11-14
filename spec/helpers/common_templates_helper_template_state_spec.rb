# frozen_string_literal: true

# CommonTemplatesHelper#edit_form_template_state builds the locals for the state-only template partial
# that an edit form renders (live, historical and embedded forms alike). These specs check that it:
# - returns nil when there is no definition or option type config, or the model type has no mapping
# - dispatches on the form object's model_data_type for dynamic models, activity logs and external identifiers
# - adds template_version_token and a matching vdef_version ("v<token>") taken from the template
#   definition it is given, so a form for an older record carries its own definition version and an
#   embedded form carries the version of its own definition, never the outer form's
# - uses the given user, defaulting to current_user

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe CommonTemplatesHelper, type: :helper do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport
  include OptionsSupport

  describe '#edit_form_template_state' do
    let(:option_type_config) { double('option type config') }
    let(:user) { double('user') }

    describe 'when not applicable' do
      let(:form_object_instance) { double('form object', model_data_type: :dynamic_model) }
      let(:template_definition) { double('definition', template_version_token: 5) }

      it 'returns nil without a template definition' do
        expect(OptionConfigs::TemplateOptionMapping).not_to receive(:mapping_for)

        expect(helper.edit_form_template_state(form_object_instance, option_type_config,
                                               template_definition: nil, user:)).to be_nil
      end

      it 'returns nil without an option type config' do
        expect(OptionConfigs::TemplateOptionMapping).not_to receive(:mapping_for)

        expect(helper.edit_form_template_state(form_object_instance, nil,
                                               template_definition:, user:)).to be_nil
      end

      it 'returns nil when the model type has no mapping' do
        form_object_instance = double('player info', model_data_type: :player_info)

        expect(helper.edit_form_template_state(form_object_instance, option_type_config,
                                               template_definition:, user:)).to be_nil
      end
    end

    describe 'dispatch and version labelling' do
      %i[dynamic_model activity_log external_identifier].each do |model_data_type|
        it "maps a #{model_data_type} for the given definition and labels it with the definition token" do
          form_object_instance = double('form object', model_data_type:)
          template_definition = double('definition', template_version_token: 321)
          mapping_method = "#{model_data_type}_mapping"

          expect(OptionConfigs::TemplateOptionMapping).to receive(mapping_method)
            .with(template_definition, option_type_config, user).and_return({ name: 'mapped' })

          expect(helper.edit_form_template_state(form_object_instance, option_type_config,
                                                 template_definition:, user:))
            .to eq({ name: 'mapped', template_version_token: 321, vdef_version: 'v321' })
        end
      end

      it 'labels with token 0 for a definition without a template version token' do
        form_object_instance = double('form object', model_data_type: :dynamic_model)
        template_definition = double('definition')
        allow(OptionConfigs::TemplateOptionMapping).to receive(:dynamic_model_mapping).and_return({})

        expect(helper.edit_form_template_state(form_object_instance, option_type_config,
                                               template_definition:, user:))
          .to include(template_version_token: 0, vdef_version: 'v0')
      end

      it 'uses the helper current_user by default' do
        form_object_instance = double('form object', model_data_type: :dynamic_model)
        template_definition = double('definition', template_version_token: 7)
        allow(helper).to receive(:current_user).and_return(user)

        expect(OptionConfigs::TemplateOptionMapping).to receive(:dynamic_model_mapping)
          .with(template_definition, option_type_config, user).and_return({})

        helper.edit_form_template_state(form_object_instance, option_type_config, template_definition:)
      end
    end

    describe 'with a versioned dynamic model' do
      let(:table_name) { 'test_created_by_vfl_recs' }

      before :all do
        change_setting('AllowDynamicMigrations', true)
        @prev_disable_vdef = Settings::DisableVDef
        change_setting('DisableVDef', false)
      end

      after :all do
        change_setting('AllowDynamicMigrations', false)
        change_setting('DisableVDef', @prev_disable_vdef)
      end

      before_all do
        unless Admin::MigrationGenerator.table_exists? 'test_created_by_vfl_recs'
          TableGenerators.dynamic_models_table('test_created_by_vfl_recs', :create_do,
                                               'test1', 'test2', 'created_by_user_id',
                                               'use_def_version_at', 'text_array')
        end

        @user0, = create_user
        create_admin
        create_user
        setup_access :trackers
        setup_access :tracker_histories
        @master = Master.create! current_user: @user
        @master.current_user = @user

        DynamicModel.active.where(table_name: 'test_created_by_vfl_recs').reload.each { |dm| dm.disable!(@admin) }
        begin
          if DynamicModel.const_defined?(:TestCreatedByVflRec, false)
            DynamicModel.send(:remove_const, :TestCreatedByVflRec)
          end
        rescue NameError
          # Constant may have been removed by another parallel test
        end

        @dmdef = DynamicModel.create! current_admin: @admin,
                                      name: 'test created by',
                                      table_name: 'test_created_by_vfl_recs',
                                      primary_key_name: :id,
                                      foreign_key_name: :master_id,
                                      field_list: 'test1 test2',
                                      category: :test
        @dmdef.current_admin = @admin
        @dmdef.update_tracker_events
        setup_access :dynamic_model__test_created_by_vfl_recs, user: @user
        setup_access :dynamic_model__test_created_by_vfl_recs, user: @user0
        @dmdef.send :reset_all_versions

        sleep 2
        @old_record_id = @master.dynamic_model__test_created_by_vfl_recs.create!(test1: 'v1_record').id
        sleep 2

        change_setting('AllowDynamicMigrations', nil)
        @dmdef.current_admin = @admin
        @dmdef.update!(field_list: 'test1 test2 text_array')
        change_setting('AllowDynamicMigrations', true)
        @dmdef.force_option_config_parse
        @new_record_id = @master.dynamic_model__test_created_by_vfl_recs.create!(test1: 'v2_record').id
      end

      def record(id)
        rec = DynamicModel::TestCreatedByVflRec.find(id)
        rec.current_user = @user
        rec
      end

      def state_for(rec)
        helper.edit_form_template_state(rec, rec.option_type_config,
                                        template_definition: rec.versioned_definition, user: @user)
      end

      it 'labels a live record with the live definition token and its full mapping' do
        rec = record(@new_record_id)
        state = state_for(rec)

        expect(state[:model_data_type]).to eq :dynamic_model
        expect(state[:def_record]).to eq rec.versioned_definition
        expect(state[:template_version_token]).to eq rec.versioned_definition.template_version_token
        expect(state[:vdef_version]).to eq "v#{state[:template_version_token]}"
        expect(state[:item_list]).to include 'text_array'
      end

      it 'labels a record created under an older definition with that older version' do
        old_rec = record(@old_record_id)
        live_state = state_for(record(@new_record_id))
        state = state_for(old_rec)

        expect(old_rec.versioned_definition.def_version).to be_present
        expect(state[:template_version_token]).to eq old_rec.versioned_definition.def_version.to_i
        expect(state[:vdef_version]).to eq "v#{old_rec.versioned_definition.def_version.to_i}"
        expect(state[:vdef_version]).not_to eq live_state[:vdef_version]
        expect(state[:item_list]).not_to include 'text_array'
      end

      it 'labels each form with its own definition, as for an embedded form beside an outer one' do
        outer = state_for(record(@new_record_id))
        embedded = state_for(record(@old_record_id))

        expect(embedded[:vdef_version]).not_to eq outer[:vdef_version]
        expect(embedded[:def_version]).not_to eq outer[:def_version]
      end
    end
  end
end
