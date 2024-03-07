# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DynamicStorage, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  describe 'dynamic storage for Redcap project' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM without multiple choice summary fields
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      @table_name = "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      @ds = ds = Redcap::DynamicStorage.new rc, @table_name
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      reset_mocks
    end

    it 'returns fields and db_columns to be used to defined fields for a dynamic model' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      ds = Redcap::DynamicStorage.new(rc, 'redcap_test.temp')

      dd = rc.redcap_data_dictionary

      all_rf = dd.all_retrievable_fields

      db_columns = ds.send :db_columns
      expect(db_columns).to be_a Hash
      expect(db_columns.keys).to eq all_rf.keys
      expect(db_columns).to eq(
        record_id: { type: 'string' },
        dob: { type: 'date' },
        current_weight: { type: 'decimal' },
        smoketime___pnfl: { type: 'boolean' },
        smoketime___dnfl: { type: 'boolean' },
        smoketime___anfl: { type: 'boolean' },
        smoke_start: { type: 'decimal' },
        smoke_stop: { type: 'decimal' },
        smoke_curr: { type: 'string' },
        demog_date: { type: 'timestamp' },
        ncmedrec_add: { type: 'string' },
        ladder_wealth: { type: 'string' },
        ladder_comm: { type: 'string' },
        born_address: { type: 'string' },
        twelveyrs_address: { type: 'string' },
        othealth___complete: { type: 'boolean' },
        othealth_date: { type: 'timestamp' },
        q2_survey_complete: { type: 'integer' },
        sdfsdaf___0: { type: 'boolean' },
        sdfsdaf___1: { type: 'boolean' },
        sdfsdaf___2: { type: 'boolean' },
        rtyrtyrt___0: { type: 'boolean' },
        rtyrtyrt___1: { type: 'boolean' },
        rtyrtyrt___2: { type: 'boolean' },
        test_field: { type: 'string' },
        test_phone: { type: 'string' },
        i57: { type: 'integer' },
        f57: { type: 'decimal' },
        dd: { type: 'timestamp' },
        yes_or_no: { type: 'boolean' },
        test_complete: { type: 'integer' }
      )
    end

    it 'generates a migration for a dynamic model' do
      dmclass = @dm.implementation_class
      expect(dmclass < Dynamic::DynamicModelBase).to be true
    end

    it 'evaluates branching logic to produce show_if conditions' do
      @dm.option_configs(force: true)
      d = @dm.default_options
      cs = d.show_if_condition_strings
      expect(cs.keys).to eq %i[placeholder_smoketime smoketime___pnfl smoketime___dnfl smoketime___anfl smoke_start smoke_stop smoke_curr]
      expect(cs[:placeholder_smoketime]).to eq "[smoke] = '1' or [smoke] = '2'"
      expect(d.show_if[:placeholder_smoketime]).to eq(
        any_0: {
          all_nonblock_0: { smoke: '1' },
          all_nonblock_1: {
            all_dupvar_0: { smoke: '2' }
          }
        }
      )
    end

    it 'adds a config library to the dynamic model' do
      rc = Redcap::ProjectAdmin.active.find_by(name: @project[:name])
      rc.current_admin = @admin
      dm = @ds.dynamic_model
      table_name = dm.implementation_class.table_name

      # Create a config library (fail quietly if it exists)
      Admin::ConfigLibrary.create(name: 'test_library', category: 'redcap', format: 'yaml', current_admin: @admin)

      prefix_config_library_string = '# @library redcap test_library'

      hasit = dm.options.include?(prefix_config_library_string)
      expect(hasit).to be false
      # Since no config library has been set it is valid not to find one
      expect(rc.dynamic_model_config_library_valid?).to be true

      rc.data_options.prefix_dynamic_model_config_library = 'redcap test_library'
      # rc.save!

      hasit = dm.options.include?(prefix_config_library_string)
      expect(hasit).to be false
      # The dynamic model has not been set up yet, so is invalid
      expect(rc.dynamic_model_config_library_valid?).to be_falsey

      rc.api_key = @project[:api_key]
      rc.dynamic_model_table = table_name
      rc.save!

      rc.update_dynamic_model
      dm = rc.dynamic_storage.dynamic_model
      hasit = dm.options.include?(prefix_config_library_string)
      expect(hasit).to be true
      expect(rc.dynamic_model_config_library_valid?).to be true
    end

    it 'creates the model with a human name' do
      project_name = @project[:name]
      rc = Redcap::ProjectAdmin.active.find_by(name: project_name)
      rc.current_admin = @admin
      dm = @ds.dynamic_model
      expect(dm.name).to eq project_name
    end
  end

  describe 'dynamic storage for Redcap project with multiple choice summary fields' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM with multiple choice summary fields
      rc = Redcap::ProjectAdmin.active.first
      rc.data_options.add_multi_choice_summary_fields = true
      rc.current_admin = @admin
      rc.save

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      create_admin
      reset_mocks
    end

    it 'allows a configuration to include an array column for each checkbox field group, in addition to individual boolean choice fields' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.data_options.add_multi_choice_summary_fields = true
      rc.save

      ds = Redcap::DynamicStorage.new(rc, 'redcap_test.temp_mcf')

      dd = rc.redcap_data_dictionary

      all_rf = dd.all_retrievable_fields

      db_columns = ds.send :db_columns
      expect(db_columns).to be_a Hash
      expect(db_columns.keys.select { |fn| !fn.to_s.end_with?('_chosen_array') }).to eq all_rf.keys

      all_rf_summ = dd.all_retrievable_fields(summary_fields: true)
      expect(db_columns.keys).to eq all_rf_summ.keys

      expect(all_rf_summ[:smoketime_chosen_array].field_type.name).to eq :checkbox_chosen_array

      exp_hash = {

        record_id: { type: 'string' },
        dob: { type: 'date' },
        current_weight: { type: 'decimal' },
        smoketime_chosen_array: { type: 'string', array: true },
        smoketime___pnfl: { type: 'boolean' },
        smoketime___dnfl: { type: 'boolean' },
        smoketime___anfl: { type: 'boolean' },
        smoke_start: { type: 'decimal' },
        smoke_stop: { type: 'decimal' },
        smoke_curr: { type: 'string' },
        demog_date: { type: 'timestamp' },
        ncmedrec_add: { type: 'string' },
        ladder_wealth: { type: 'string' },
        ladder_comm: { type: 'string' },
        born_address: { type: 'string' },
        twelveyrs_address: { type: 'string' },
        othealth___complete: { type: 'boolean' },
        othealth_date: { type: 'timestamp' },
        q2_survey_complete: { type: 'integer' },
        sdfsdaf_chosen_array: { type: 'string', array: true },
        sdfsdaf___0: { type: 'boolean' },
        sdfsdaf___1: { type: 'boolean' },
        sdfsdaf___2: { type: 'boolean' },
        rtyrtyrt_chosen_array: { type: 'string', array: true },
        rtyrtyrt___0: { type: 'boolean' },
        rtyrtyrt___1: { type: 'boolean' },
        rtyrtyrt___2: { type: 'boolean' },
        test_field: { type: 'string' },
        test_phone: { type: 'string' },
        i57: { type: 'integer' },
        f57: { type: 'decimal' },
        dd: { type: 'timestamp' },
        yes_or_no: { type: 'boolean' },
        test_complete: { type: 'integer' }
      }

      expect(db_columns).to eq(exp_hash)
    end
  end
end
