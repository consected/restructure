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

    it 'updates the existing _configurations without overwriting them' do
      project_name = @project[:name]
      rc = Redcap::ProjectAdmin.active.find_by(name: project_name)
      rc.current_admin = @admin
      dm = @ds.dynamic_model
      options = dm.options
      expect(options.index(/_configurations_from_model_generator:.*$/)).to be_truthy

      # Set up a new configurations item
      orig_configs = <<~END_TEXT
        _configurations:
          use_current_version: true
      END_TEXT
      dm.options = dm.options.sub(/^_configurations:.*$/, '')
      dm.options = "#{orig_configs}\n#{dm.options}"
      dm.save!
      dm.reload

      expect(dm.options.index(/^  use_current_version: true$/)).to be_truthy

      # Ensure we don't overwrite the new configurations item when we recreate the dynamic model
      # First, simulate adding a new option to the _configurations through the Redcap project admin
      @ds.project_admin.data_options.associate_master_through_external_identifer = 'dynamic_model__tests'
      #  Update the dynamic model
      @ds.create_dynamic_model
      # Reload the dynamic model
      new_options = @ds.dynamic_model(force: true).options
      expect(new_options.index(/^  use_current_version: true$/)).to be_truthy
      expect(new_options.index(/^  foreign_key_through_external_id: dynamic_model__tests$/)).to be_truthy

      expect(dm.configurations[:use_current_version]).to be true
      expect(dm.configurations[:foreign_key_through_external_id]).to eq 'dynamic_model__tests'
      expect(dm.configurations[:option_type_attr_name]).to eq 'option_type'
    end

    it 'automatically sets the option_type field value' do
      project_name = @project[:name]
      rc = Redcap::ProjectAdmin.active.find_by(name: project_name)
      rc.current_admin = @admin

      # Reload the dynamic model
      dm = @ds.dynamic_model(force: true)

      otc = dm.option_type_config_for(:default)

      expect(otc.field_options[:option_type]).to respond_to(:[], :key?)
      expect(otc.field_options.dig(:option_type, :active_value)).to eq('{{#if q2_survey_complete}}q2_survey{{else if test_complete}}test{{/if}}')
    end
  end

  describe 'dynamic storage for Redcap project getting fields by option type' do
    before :all do
      create_admin
      setup_redcap_project_admin_configs
      setup_repeat_instrument_fields
    end

    before :example do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      @metadata_project = @projects.find { |p| p[:name] == 'metadata' }
    end
    it 'gets a list of field names by option type from the data dictionary' do
      setup_repeat_instrument_fields
      rc = @project_admin_metadata
      rc.reload
      rc.current_admin = @admin

      fbot = rc.dynamic_storage.field_names_by_option_type
      expect(fbot).to be_a Hash
      expect(fbot.keys).to eq %i[static_variable_information visitspecific_information]
      expect(fbot[:static_variable_information]).to eq %i[varname var_label var_type placeholder_restrict_var restrict_var___0 restrict_var___1 restrict_var___2 restrict_var___3 restrict_var___4 oth_restrict domain_viva placeholder_subdomain subdomain___1 subdomain___2 target_of_q data_source val_instr ext_instrument internal_instrument doc_yn doc_link long_yn placeholder_long_timepts long_timepts___1 long_timepts___2 long_timepts___3 long_timepts___4 long_timepts___5 long_timepts___6 long_timepts___7 long_timepts___8 long_timepts___9 long_timepts___10 long_timepts___11 long_timepts___12 long_timepts___13 long_timepts___14 long_timepts___15 long_timepts___16 long_timepts___17 long_timepts___18 long_timepts___19 long_timepts___20 long_timepts___21 long_timepts___22 long_timepts___23]
      expect(fbot[:visitspecific_information]).to eq %i[event_type visit_name visit_time assay_specimen assay_type lab_assay_dataset form_label_ep placeholder_form_version_ep form_version_ep___1 form_version_ep___2 form_version_ep___3 form_version_ep___4 form_version_ep___5 form_version_ep___6 form_version_ep___7 form_version_ep___8 form_label_mp placeholder_form_version_mp form_version_mp___1 form_version_mp___2 form_version_mp___3 form_version_mp___4 form_label_del placeholder_form_version_del form_version_del___1 form_version_del___2 form_version_del___3 form_version_del___4 form_version_del___5 form_version_del___6 form_version_del___7 form_label_6m placeholder_form_version_6m form_version_6m___1 form_version_6m___2 form_version_6m___3 form_version_6m___4 form_version_6m___5 form_version_6m___6 form_version_6m___7 form_version_6m___8 form_version_6m___9 form_version_6m___10 form_label_1y placeholder_form_version_1y form_version_1y___1 form_label_2y placeholder_form_version_2y form_version_2y___1 form_label_3y placeholder_form_version_3y form_version_3y___1 form_version_3y___2 form_version_3y___3 form_version_3y___4 form_version_3y___5 form_version_3y___6 form_version_3y___7 form_version_3y___8 form_version_3y___9 form_version_3y___10 form_version_3y___11 form_version_3y___12 form_version_3y___13 form_version_3y___14 form_label_4y placeholder_form_version_4y form_version_4y___1 form_label_5y placeholder_form_version_5y form_version_5y___1 form_label_6y placeholder_form_version_6y form_version_6y___1 form_label_7y placeholder_form_version_7y form_version_7y___1 form_version_7y___2 form_version_7y___3 form_version_7y___4 form_version_7y___5 form_version_7y___6 form_version_7y___7 form_version_7y___8 form_version_7y___9 form_version_7y___10 form_version_7y___11 form_version_7y___12 form_version_7y___13 form_version_7y___14 form_version_7y___15 form_version_7y___16 form_version_7y___17 form_label_8y placeholder_form_version_8y form_version_8y___1 form_label_9y placeholder_form_version_9y form_version_9y___1 form_version_9y___2 form_label_10y placeholder_form_version_10y form_version_10y___1 form_version_10y___2 form_label_11y placeholder_form_version_11y form_version_11y___1 form_version_11y___2 form_label_12y placeholder_form_version_12y form_version_12y___1 form_version_12y___2 form_version_12y___3 form_version_12y___4 form_version_12y___5 form_version_12y___6 form_version_12y___7 form_version_12y___8 form_version_12y___9 form_version_12y___10 form_version_12y___11 form_version_12y___12 form_version_12y___13 form_version_12y___14 form_version_12y___15 form_version_12y___16 form_label_14y placeholder_form_version_14y form_version_14y___1 form_version_14y___2 form_label_15y placeholder_form_version_15y form_version_15y___1 form_version_15y___2 form_label_16y placeholder_form_version_16y form_version_16y___1 form_version_16y___2 form_label_mt form_version_mt form_label_19y placeholder_form_version_19y form_version_19y___1 form_version_19y___2 not_time_specific var_level units model_type response_options elig_sample elig_n actual_n an_var orig_deriv placeholder_corr_derived_yn corr_derived_yn___0 corr_derived_yn___1 der_varname dervar_explain orig_varnames]
    end

    it 'generates a dynamic model with fields by option type from the data dictionary' do
      setup_repeat_instrument_fields
      rc = @project_admin_metadata
      rc.reload
      rc.current_admin = @admin
      ds = rc.dynamic_storage
      dm = ds.dynamic_model
      expect(dm).to be_a DynamicModel
      dm.option_configs(force: true)

      expect(dm.option_configs_names).to eq %i[default static_variable_information visitspecific_information]
      expect(dm.configurations[:option_type_attr_name]).to eq 'redcap_repeat_instrument'

      # Check the configuration for the default option type
      oc = dm.option_type_config_for(:default)
      # We always have the full set of fields in the default option type if no fields are explicitly set
      expect(oc.fields.sort).to eq(dm.field_list_array.sort)

      # Check the configuration for the static_variable_information option type
      # The fields should contain all the real retrievable fields for the dynamic model and only the placeholders for the
      # current option type
      oc = dm.option_type_config_for(:static_variable_information)
      expect(oc.fields).to eq %w[varname var_label var_type placeholder_restrict_var restrict_var___0 restrict_var___1 restrict_var___2 restrict_var___3 restrict_var___4 oth_restrict domain_viva placeholder_subdomain subdomain___1 subdomain___2 target_of_q data_source val_instr ext_instrument internal_instrument doc_yn doc_link long_yn placeholder_long_timepts long_timepts___1 long_timepts___2 long_timepts___3 long_timepts___4 long_timepts___5 long_timepts___6 long_timepts___7 long_timepts___8 long_timepts___9 long_timepts___10 long_timepts___11 long_timepts___12 long_timepts___13 long_timepts___14 long_timepts___15 long_timepts___16 long_timepts___17 long_timepts___18 long_timepts___19 long_timepts___20 long_timepts___21 long_timepts___22 long_timepts___23
                                 event_type visit_name visit_time assay_specimen assay_type lab_assay_dataset form_label_ep form_version_ep___1 form_version_ep___2 form_version_ep___3 form_version_ep___4 form_version_ep___5 form_version_ep___6 form_version_ep___7 form_version_ep___8 form_label_mp form_version_mp___1 form_version_mp___2 form_version_mp___3 form_version_mp___4 form_label_del form_version_del___1 form_version_del___2 form_version_del___3 form_version_del___4 form_version_del___5 form_version_del___6 form_version_del___7 form_label_6m form_version_6m___1 form_version_6m___2 form_version_6m___3 form_version_6m___4 form_version_6m___5 form_version_6m___6 form_version_6m___7 form_version_6m___8 form_version_6m___9 form_version_6m___10 form_label_1y form_version_1y___1 form_label_2y form_version_2y___1 form_label_3y form_version_3y___1 form_version_3y___2 form_version_3y___3 form_version_3y___4 form_version_3y___5 form_version_3y___6 form_version_3y___7 form_version_3y___8 form_version_3y___9 form_version_3y___10 form_version_3y___11 form_version_3y___12 form_version_3y___13 form_version_3y___14 form_label_4y form_version_4y___1 form_label_5y form_version_5y___1 form_label_6y form_version_6y___1 form_label_7y form_version_7y___1 form_version_7y___2 form_version_7y___3 form_version_7y___4 form_version_7y___5 form_version_7y___6 form_version_7y___7 form_version_7y___8 form_version_7y___9 form_version_7y___10 form_version_7y___11 form_version_7y___12 form_version_7y___13 form_version_7y___14 form_version_7y___15 form_version_7y___16 form_version_7y___17 form_label_8y form_version_8y___1 form_label_9y form_version_9y___1 form_version_9y___2 form_label_10y form_version_10y___1 form_version_10y___2 form_label_11y form_version_11y___1 form_version_11y___2 form_label_12y form_version_12y___1 form_version_12y___2 form_version_12y___3 form_version_12y___4 form_version_12y___5 form_version_12y___6 form_version_12y___7 form_version_12y___8 form_version_12y___9 form_version_12y___10 form_version_12y___11 form_version_12y___12 form_version_12y___13 form_version_12y___14 form_version_12y___15 form_version_12y___16 form_label_14y form_version_14y___1 form_version_14y___2 form_label_15y form_version_15y___1 form_version_15y___2 form_label_16y form_version_16y___1 form_version_16y___2 form_label_mt form_version_mt form_label_19y form_version_19y___1 form_version_19y___2 not_time_specific var_level units model_type response_options elig_sample elig_n actual_n an_var orig_deriv corr_derived_yn___0 corr_derived_yn___1 der_varname dervar_explain orig_varnames
                                 redcap_repeat_instrument redcap_repeat_instance static_variable_information_complete visitspecific_information_complete]

      # Check the configuration for the visitspecific_information option type
      # The fields should contain all the real retrievable fields for the dynamic model and only the placeholders for the
      # current option type
      oc = dm.option_type_config_for(:visitspecific_information)
      expect(oc.fields).to eq %w[varname var_label var_type restrict_var___0 restrict_var___1 restrict_var___2 restrict_var___3 restrict_var___4 oth_restrict domain_viva subdomain___1 subdomain___2 target_of_q data_source val_instr ext_instrument internal_instrument doc_yn doc_link long_yn long_timepts___1 long_timepts___2 long_timepts___3 long_timepts___4 long_timepts___5 long_timepts___6 long_timepts___7 long_timepts___8 long_timepts___9 long_timepts___10 long_timepts___11 long_timepts___12 long_timepts___13 long_timepts___14 long_timepts___15 long_timepts___16 long_timepts___17 long_timepts___18 long_timepts___19 long_timepts___20 long_timepts___21 long_timepts___22 long_timepts___23
                                 event_type visit_name visit_time assay_specimen assay_type lab_assay_dataset form_label_ep placeholder_form_version_ep form_version_ep___1 form_version_ep___2 form_version_ep___3 form_version_ep___4 form_version_ep___5 form_version_ep___6 form_version_ep___7 form_version_ep___8 form_label_mp placeholder_form_version_mp form_version_mp___1 form_version_mp___2 form_version_mp___3 form_version_mp___4 form_label_del placeholder_form_version_del form_version_del___1 form_version_del___2 form_version_del___3 form_version_del___4 form_version_del___5 form_version_del___6 form_version_del___7 form_label_6m placeholder_form_version_6m form_version_6m___1 form_version_6m___2 form_version_6m___3 form_version_6m___4 form_version_6m___5 form_version_6m___6 form_version_6m___7 form_version_6m___8 form_version_6m___9 form_version_6m___10 form_label_1y placeholder_form_version_1y form_version_1y___1 form_label_2y placeholder_form_version_2y form_version_2y___1 form_label_3y placeholder_form_version_3y form_version_3y___1 form_version_3y___2 form_version_3y___3 form_version_3y___4 form_version_3y___5 form_version_3y___6 form_version_3y___7 form_version_3y___8 form_version_3y___9 form_version_3y___10 form_version_3y___11 form_version_3y___12 form_version_3y___13 form_version_3y___14 form_label_4y placeholder_form_version_4y form_version_4y___1 form_label_5y placeholder_form_version_5y form_version_5y___1 form_label_6y placeholder_form_version_6y form_version_6y___1 form_label_7y placeholder_form_version_7y form_version_7y___1 form_version_7y___2 form_version_7y___3 form_version_7y___4 form_version_7y___5 form_version_7y___6 form_version_7y___7 form_version_7y___8 form_version_7y___9 form_version_7y___10 form_version_7y___11 form_version_7y___12 form_version_7y___13 form_version_7y___14 form_version_7y___15 form_version_7y___16 form_version_7y___17 form_label_8y placeholder_form_version_8y form_version_8y___1 form_label_9y placeholder_form_version_9y form_version_9y___1 form_version_9y___2 form_label_10y placeholder_form_version_10y form_version_10y___1 form_version_10y___2 form_label_11y placeholder_form_version_11y form_version_11y___1 form_version_11y___2 form_label_12y placeholder_form_version_12y form_version_12y___1 form_version_12y___2 form_version_12y___3 form_version_12y___4 form_version_12y___5 form_version_12y___6 form_version_12y___7 form_version_12y___8 form_version_12y___9 form_version_12y___10 form_version_12y___11 form_version_12y___12 form_version_12y___13 form_version_12y___14 form_version_12y___15 form_version_12y___16 form_label_14y placeholder_form_version_14y form_version_14y___1 form_version_14y___2 form_label_15y placeholder_form_version_15y form_version_15y___1 form_version_15y___2 form_label_16y placeholder_form_version_16y form_version_16y___1 form_version_16y___2 form_label_mt form_version_mt form_label_19y placeholder_form_version_19y form_version_19y___1 form_version_19y___2 not_time_specific var_level units model_type response_options elig_sample elig_n actual_n an_var orig_deriv placeholder_corr_derived_yn corr_derived_yn___0 corr_derived_yn___1 der_varname dervar_explain orig_varnames
                                 redcap_repeat_instrument redcap_repeat_instance static_variable_information_complete visitspecific_information_complete]
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
      expect(db_columns.keys.reject { |fn| fn.to_s.end_with?('_chosen_array') }).to eq all_rf.keys

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
