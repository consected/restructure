# frozen_string_literal: true

# Demonstrates the record scope that conditional calculations and curly brace
# substitutions operate within, for definitions that reach their master record in
# different ways:
#
# - a standalone dynamic model, with no foreign key name at all
# - a dynamic model with a foreign key name other than master_id, and no
#   _configurations.foreign_key_through_external_id to resolve it
# - a dynamic model whose table already has a master_id column
# - a dynamic model carrying a master crosswalk attribute (msid)
# - a dynamic model joined to the master through an external identifier, using
#   _configurations.foreign_key_through_external_id
#
# These examples back the admin documentation in
# docs/admin_reference/general/scoping.md, so that the scoping rules described
# there cannot silently drift away from the implementation.
require 'rails_helper'

RSpec.describe 'Definition scoping', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport
  include TestNoMasterDmRecSupport

  # Create a dynamic model against a table built directly with SQL, so that the
  # column layout under test is exact and no dynamic migration is needed.
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
    setup_access :"dynamic_model__#{name}", user: @user0
    dm
  end

  before :example do
    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    let_user_create_player_contacts
  end

  describe 'a standalone definition, with no foreign key name' do
    before :example do
      setup_test_no_master_dm_rec_dynamic_model
      @master = create_master
      @pc = @master.player_contacts.create!(data: '(516)123-7612 11', rec_type: 'phone', rank: 10, source: 'nflpa')
      @rec = create_test_no_master_dm_rec(sample_test_no_master_dm_rec_attrs)
    end

    it 'has no master association and no master id' do
      expect(DynamicModel::TestNoMasterDmRec.no_master_association).to be true
      expect(@rec.master_id).to be nil
    end

    it 'reaches the master through a crosswalk value held on the record' do
      @rec.update!(alt_id: @master.msid, current_user: @user)

      conf = { all: { masters: { msid: { this: 'alt_id' }, id: 'return_value' } } }
      expect(ConditionalActions.new(conf, @rec).get_this_val).to eq @master.id

      # The matched master correlates any further tables named in the block
      conf = { all: { masters: { msid: { this: 'alt_id' } }, player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be true

      conf = { all: { masters: { msid: { this: 'alt_id' } }, player_contacts: { data: 'no such value' } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be false
    end

    it 'gains a full master scope when backed by a view that resolves the master' do
      @rec.update!(alt_id: @master.msid, current_user: @user)

      # The equivalent of a _configurations.view_sql definition, built directly so the
      # example does not depend on a dynamic migration
      ActiveRecord::Base.connection.execute <<~SQL
        CREATE OR REPLACE VIEW dynamic_test.test_xwalk_views AS
        select s.id, m.id master_id, s.data, s.info, s.alt_id, s.user_id, s.created_at, s.updated_at
        from test.test_no_master_dm_recs s
        inner join masters m on m.msid = s.alt_id;
      SQL

      DynamicModel.active.where(table_name: 'test_xwalk_views').each { |d| d.disable!(@admin) }
      dm = DynamicModel.create!(current_admin: @admin,
                                name: 'test xwalk view',
                                table_name: 'test_xwalk_views',
                                schema_name: 'dynamic_test',
                                primary_key_name: :id,
                                foreign_key_name: :master_id,
                                category: :test,
                                options: "_configurations:\n  prevent_migrations: true\n")
      dm.current_admin = @admin
      dm.update_tracker_events
      setup_access :dynamic_model__test_xwalk_views, user: @user

      klass = dm.implementation_class
      expect(klass.no_master_association).to be false

      view_rec = klass.first
      expect(view_rec.master_id).to eq @master.id

      conf = { all: { player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, view_rec).calc_action_if).to be true
      expect(Formatter::Substitution.substitute('[{{player_contacts.data}}]', data: view_rec)).to eq "[#{@pc.data}]"
    end

    it 'fails to evaluate a table condition that relies on the default master scope' do
      conf = { all: { player_contacts: { data: @pc.data } } }

      expect { ConditionalActions.new(conf, @rec).calc_action_if }
        .to raise_error(ActiveRecord::ConfigurationError, /Can't join .* to association named 'player_contacts'/)
    end

    it 'evaluates a table condition when the scope is widened with masters or no_masters' do
      conf = { all: { masters: {}, player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be true

      conf = { all: { no_masters: {}, player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be true

      conf = { all: { masters: {}, player_contacts: { data: 'not a real number' } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be false
    end

    it 'requires no_masters when the table being searched is itself standalone' do
      standalone_conds = { dynamic_model__test_no_master_dm_recs: { data: @rec.data } }

      expect { ConditionalActions.new({ all: { masters: {}, **standalone_conds } }, @rec).calc_action_if }
        .to raise_error(ActiveRecord::ConfigurationError,
                        /Can't join 'Master' to association named 'dynamic_model__test_no_master_dm_recs'/)

      expect(ConditionalActions.new({ all: { no_masters: {}, **standalone_conds } }, @rec).calc_action_if).to be true
    end

    it 'correlates several master tables through a shared master, which no_masters can not do' do
      setup_access :addresses, user: @user
      @master.addresses.create!(city: 'portland', state: 'OR', zip: '12345', rank: 0, rec_type: 'home',
                                source: 'nflpa')
      other = create_master
      other_pc = other.player_contacts.create!(data: '(516)123-7612 99', rec_type: 'phone', rank: 10,
                                               source: 'nflpa')

      conf_for = lambda do |directive, contact_data|
        { all: { directive => {}, player_contacts: { data: contact_data }, addresses: { city: 'portland' } } }
      end

      expect(ConditionalActions.new(conf_for.call(:masters, @pc.data), @rec).calc_action_if).to be true
      expect(ConditionalActions.new(conf_for.call(:masters, other_pc.data), @rec).calc_action_if).to be false

      # The failed statement aborts the transaction, so isolate it in a savepoint
      expect do
        ActiveRecord::Base.transaction(requires_new: true) do
          ConditionalActions.new(conf_for.call(:no_masters, @pc.data), @rec).calc_action_if
        end
      end.to raise_error(ActiveRecord::StatementInvalid, /missing FROM-clause entry for table "addresses"/)
    end

    it 'substitutes nothing for a master association, since there is no master' do
      res = Formatter::Substitution.substitute('[{{player_contacts.data}}]', data: @rec, ignore_missing: true)
      expect(res).to eq '[]'

      expect { Formatter::Substitution.substitute('[{{player_contacts.data}}]', data: @rec) }
        .to raise_error(FphsException, /does not contain the tag 'data'/)
    end
  end

  describe 'a definition with a foreign key name that can not be resolved to a master' do
    before :example do
      setup_dynamic_model_for_table 'test_unresolved_fk_recs',
                                    'data character varying, alt_master_id integer',
                                    name: 'test unresolved fk rec',
                                    foreign_key_name: :alt_master_id,
                                    field_list: 'alt_master_id data'
      @master = create_master
    end

    it 'can not save a record, because master_id does not exist' do
      klass = DynamicModel::TestUnresolvedFkRec
      expect(klass.no_master_association).to be false

      expect { klass.create!(alt_master_id: @master.id, data: 'x', current_user: @user) }
        .to raise_error(NoMethodError, /master_id/)
    end
  end

  describe 'a definition with the foreign key name set to a masters crosswalk column' do
    it 'can not use a crosswalk column such as msid to drive the master association' do
      dm = setup_dynamic_model_for_table 'test_msid_fk_recs',
                                         'data character varying, msid integer',
                                         name: 'test msid fk rec',
                                         primary_key_name: :msid,
                                         foreign_key_name: :msid,
                                         field_list: 'msid data'

      # primary_key_name names the masters column to match, but doubles as this table's
      # own primary key, and is forced back to id whenever the table has an id column
      expect(dm.primary_key_name).to eq 'id'
      expect(dm.foreign_key_name).to eq 'msid'
      expect(dm.implementation_class.primary_key).to eq 'id'

      master = create_master

      # The association therefore matches masters.id against msid, not masters.msid,
      # so a valid crosswalk value resolves to nothing
      rec = dm.implementation_class.new(msid: master.msid, data: 'x')
      expect(rec.master).to be nil
      expect(Master.find_by(msid: master.msid)).to eq master

      expect { rec.save! }.to raise_error(StandardError)
    end
  end

  describe 'a definition for a table that already has a master_id column' do
    it 'forces the foreign key name to master_id when the definition is created' do
      dm = setup_dynamic_model_for_table 'test_forced_fk_recs',
                                         'data character varying, master_id integer, alt_master_id integer',
                                         name: 'test forced fk rec',
                                         foreign_key_name: :alt_master_id,
                                         field_list: 'alt_master_id data'

      expect(dm.foreign_key_name).to eq 'master_id'
    end
  end

  describe 'a definition with a master crosswalk attribute column' do
    before :example do
      setup_dynamic_model_for_table 'test_xwalk_attr_recs',
                                    'data character varying, master_id integer, msid integer',
                                    name: 'test xwalk attr rec',
                                    foreign_key_name: :master_id,
                                    field_list: 'msid data'
      @master = create_master
      @pc = @master.player_contacts.create!(data: '(516)123-7612 41', rec_type: 'phone', rank: 10, source: 'nflpa')

      @rec = DynamicModel::TestXwalkAttrRec.new(data: 'x', msid: @master.msid)
      @rec.master = @master
      @rec.save!
    end

    it 'scopes conditions and substitutions to the master, without any scope directive' do
      expect(@rec.master_id).to eq @master.id

      conf = { all: { player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be true

      expect(Formatter::Substitution.substitute('[{{player_contacts.data}}]', data: @rec)).to eq "[#{@pc.data}]"
    end

    it 'finds a master record from the crosswalk attribute with a masters condition' do
      conf = { all: { masters: { msid: @master.msid, id: 'return_value' } } }
      expect(ConditionalActions.new(conf, @rec).get_this_val).to eq @master.id
    end
  end

  describe 'a definition joined to the master through an external identifier' do
    before :example do
      @ext = ExternalIdentifier.active.first.implementation_class
      setup_test_no_master_dm_rec_dynamic_model_alt_id @ext.resource_name

      @extid = 123_456
      @master = create_master
      @ext.create(@ext.external_id_attribute => @extid, master: @master)
      @pc = @master.player_contacts.create!(data: '(516)123-7612 21', rec_type: 'phone', rank: 10, source: 'nflpa')
      @rec = create_test_no_master_dm_alt_id_rec(alt_id: @extid, data: 'd', info: 'i')
    end

    it 'resolves the master through the external identifier' do
      expect(DynamicModel::TestNoMasterDmAltIdRec.no_master_association).to be false
      expect(@rec.master).to eq @master
      expect(@rec.master_id).to eq @master.id
    end

    it 'scopes conditions and substitutions to the master, without any scope directive' do
      conf = { all: { player_contacts: { data: @pc.data } } }
      expect(ConditionalActions.new(conf, @rec).calc_action_if).to be true

      expect(Formatter::Substitution.substitute('[{{player_contacts.data}}]', data: @rec)).to eq "[#{@pc.data}]"
    end
  end
end
