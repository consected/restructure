# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for issue #1399: Classification::SelectionOptionsHandler
# .selector_with_config_overrides_processing injects a real master's id via
# `dyn_object.master_id = master_id` for every implementation class (this is
# exercised for any master-linked record whenever GeneralDataConcerns#_general_selections
# runs, e.g. during JSON serialization). Confirms this assignment does not raise for
# either kind of definition that has no physical master_id column - a masters-crosswalk
# association and a foreign_key_through_external_id association - since UserHandler's
# master_id= now discards the assignment for both (virtual_master_id?), rather than
# calling super against a column that does not exist.
RSpec.describe Classification::SelectionOptionsHandler, type: :model do
  include MasterSupport
  include ModelSupport
  include TestNoMasterDmRecSupport

  before :example do
    @user0, = create_user
    create_admin
    create_user
  end

  def setup_dynamic_model_for_table(name, columns, **defn)
    ActiveRecord::Base.connection.execute <<~END_SQL
      CREATE TABLE IF NOT EXISTS dynamic_test.#{name} (
        id bigserial primary key,
        #{columns},
        user_id bigint,
        created_at timestamp without time zone NOT NULL DEFAULT now(),
        updated_at timestamp without time zone NOT NULL DEFAULT now()
      );
    END_SQL

    DynamicModel.active.where(table_name: name).each { |d| d.disable!(@admin) }
    dm = DynamicModel.create!(current_admin: @admin,
                              table_name: name,
                              schema_name: 'dynamic_test',
                              primary_key_name: :id,
                              category: :test,
                              options: "_configurations:\n  prevent_migrations: true\n",
                              **defn)
    dm.current_admin = @admin
    dm.update_tracker_events
    setup_access :"dynamic_model__#{name}", user: @user
    dm
  end

  it 'does not raise for a foreign_key_through_external_id dynamic model' do
    ext = ExternalIdentifier.active.first.implementation_class
    setup_test_no_master_dm_rec_dynamic_model_alt_id ext.resource_name

    master = create_master
    dyn_object = DynamicModel::TestNoMasterDmAltIdRec.new(skip_presets: true)

    expect { dyn_object.master_id = master.id }.not_to raise_error
  end

  it 'does not raise for a masters-crosswalk (virtual_master_id?) dynamic model' do
    dm = setup_dynamic_model_for_table 'test_selopts_msid_fk_recs',
                                       'data character varying, msid integer',
                                       name: 'test selopts msid fk rec',
                                       primary_key_name: :id,
                                       foreign_key_name: :msid,
                                       field_list: 'msid data'

    master = create_master(@user, msid: rand(1_000_000_000))
    dyn_object = dm.implementation_class.new(skip_presets: true)

    expect { dyn_object.master_id = master.id }.not_to raise_error
  end
end
