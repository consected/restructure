# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DynamicStorage, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    `mkdir -p db/app_migrations/redcap_test; rm -f db/app_migrations/redcap_test/*test_rc*.rb`

    ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
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
end
