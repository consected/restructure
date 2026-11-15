# frozen_string_literal: true

# Tests for ConditionalActions enhancements from GitHub Issue #1142:
#
# Part A: 'lookup' sub-query value source
#   A new key :lookup in generate_match_query_condition allows a field's expected
#   comparison value to be derived from an independent ConditionalActions sub-query.
#   The sub-query is run first; its return value is substituted as the comparison
#   value for the enclosing condition field.
#
# Part B: return-flag keys on condition: hashes
#   Extends handle_condition_tag so that a condition: hash can also include
#   return_value: true, return_value_list: true, return_result: true, or
#   return_all_results: true to simultaneously filter the query AND return the
#   field value as this_val.
#
# See GitHub Issue #1142 for full requirements.

require 'rails_helper'

RSpec.describe 'Lookup sub-query and condition return-flags in ConditionalActions', type: :model do
  include ModelSupport
  include ActivityLogSupport
  include TestNoMasterDmRecSupport

  before :all do
    create_admin
    change_setting('AllowDynamicMigrations', true)
    # Create the test_lookup_dm_recs dynamic model once for AC4 (self-table sub-query test).
    # AllowDynamicMigrations being true means the underlying table is auto-created here,
    # so no separate spec migration file is needed.
    @lookup_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Lookup Dm Rec',
      table_name: 'test_lookup_dm_recs',
      primary_key_name: :id,
      foreign_key_name: nil,
      category: :test
    )
    @lookup_dm.current_admin = @admin
    @lookup_dm.update_tracker_events
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    create_user
    setup_test_no_master_dm_rec_dynamic_model
    expect(DynamicModel::TestNoMasterDmRec.no_master_association).to be true
    let_user_create :dynamic_model__test_no_master_dm_recs

    @dm1 = create_test_no_master_dm_rec(data: 'data-alpha', info: 'info-alpha')
    @dm2 = create_test_no_master_dm_rec(data: 'data-beta',  info: 'info-beta')
    @dm3 = create_test_no_master_dm_rec(data: 'data-gamma', info: 'info-gamma')
  end

  describe 'Part A: lookup sub-query value source' do
    it 'AC1: filters the outer query using a scalar value returned by a lookup sub-query' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: @dm1.id,
                    data: 'return_value'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect(ca.calc_action_if).to be true
    end

    it 'AC1b: outer query evaluates to false when the lookup value does not match the filtered record' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm3.id,
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: @dm1.id,
                    data: 'return_value'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm3
      expect(ca.calc_action_if).to be false
    end

    it 'AC6: lookup with return_value_list provides an array for IN-style filtering' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: [@dm1.id, @dm2.id],
                    data: 'return_value_list'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm3
      expect(ca.calc_action_if).to be true
    end

    it 'AC7: raises a runtime error when the lookup sub-query config has no selection-type wrapper' do
      # Without an :all/:any wrapper, ConditionalActions treats the table name as a condition
      # type and raises at runtime (ActiveRecord::ConfigurationError via calc_return_types).
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                dynamic_model__test_no_master_dm_recs: {
                  id: @dm1.id,
                  data: 'return_value'
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.calc_action_if }.to raise_error(StandardError)
    end

    it 'AC8: raises FphsException when the lookup sub-query has no return directive' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: @dm1.id,
                    data: @dm1.data
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.calc_action_if }.to raise_error(FphsException, /lookup.*return_value.*return_value_list/i)
    end

    it 'AC8b: raises FphsException when the lookup sub-query uses return_result' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: @dm1.id,
                    data: 'return_result'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.calc_action_if }.to raise_error(FphsException, /lookup.*return_value.*return_value_list/i)
    end

    it 'AC8c: raises FphsException when the lookup sub-query uses return_all_results' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    data: 'return_all_results'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.calc_action_if }.to raise_error(FphsException, /lookup.*return_value.*return_value_list/i)
    end

    it 'AC10: evaluates to false without raising an exception when the lookup sub-query matches no rows' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_no_master_dm_recs: {
                    id: -9999,
                    data: 'return_value'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.calc_action_if }.not_to raise_error
      expect(ca.calc_action_if).to be false
    end
  end

  describe 'Part B: return flags on condition: hashes' do
    it 'AC2a: condition: hash with return_value: true both filters the query and returns the field value' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm1.id,
            data: {
              condition: 'IS NOT NULL',
              return_value: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      res = ca.get_this_val
      expect(res).to eq @dm1.data
    end

    it 'AC2b: condition: hash with return_value_list: true returns an array of matching field values' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              condition: 'IS NOT NULL',
              return_value_list: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      res = ca.get_this_val
      expect(res).to be_an Array
      expect(res).to include(@dm1.data, @dm2.data, @dm3.data)
    end

    it 'AC2c: condition: hash with return_result: true returns the matching record instance' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm1.id,
            data: {
              condition: 'IS NOT NULL',
              return_result: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      res = ca.get_this_val
      expect(res).to eq @dm1
    end

    it 'AC2d: condition: hash with return_all_results: true returns all matching record instances' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              condition: 'IS NOT NULL',
              return_all_results: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      res = ca.get_this_val
      expect(res).to be_an ActiveRecord::Relation
      expect(res.length).to be >= 3
    end

    it 'AC2e: condition: IS NOT NULL with return_value: true returns nil when the field is NULL' do
      @dm_nil = create_test_no_master_dm_rec(info: 'no data')

      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm_nil.id,
            data: {
              condition: 'IS NOT NULL',
              return_value: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm_nil
      res = ca.get_this_val
      expect(res).to be_nil
      expect(ca.this_val_set?).to be true
    end

    it 'AC9: raises FphsException when a condition: hash includes more than one return_* flag' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm1.id,
            data: {
              condition: 'IS NOT NULL',
              return_value: true,
              return_value_list: true
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect { ca.get_this_val }.to raise_error(FphsException, /return/i)
    end
  end

  describe 'Parts A and B combined' do
    it 'AC3: lookup sub-query uses condition: IS NOT NULL with return_value: true; outer query uses result' do
      lookup_conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm2.id,
            data: {
              condition: 'IS NOT NULL',
              return_value: true
            }
          }
        }
      }

      outer_conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: {
              lookup: lookup_conf
            },
            info: 'return_value'
          }
        }
      }

      ca = ConditionalActions.new outer_conf, @dm2
      res = ca.get_this_val
      expect(res).to eq @dm2.info
    end
  end

  describe 'Part A: self-table sub-query' do
    before :each do
      setup_access :dynamic_model__test_lookup_dm_recs, user: @user
      let_user_create :dynamic_model__test_lookup_dm_recs

      # The auto-created table has user_id, id, created_at, updated_at — no custom columns needed
      @lookup_rec1 = DynamicModel::TestLookupDmRec.create!(current_user: @user)
      @lookup_rec2 = DynamicModel::TestLookupDmRec.create!(current_user: @user)
    end

    # AC4: When the lookup sub-query references the same table as the outer record's
    # class, no "Can't join" (self-join) error is raised and the query evaluates correctly.
    it 'AC4: lookup sub-query referencing the same table as the outer record does not raise a join error' do
      # Sub-query: look up @lookup_rec1 by id and return its user_id.
      # Outer query: filter test_lookup_dm_recs by user_id = <returned value>.
      # Both the outer query and the sub-query target the same table — this used to raise
      # "Can't join 'DynamicModel::TestLookupDmRec' to association named '...'"
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_lookup_dm_recs: {
            user_id: {
              lookup: {
                all: {
                  no_masters: {},
                  dynamic_model__test_lookup_dm_recs: {
                    id: @lookup_rec1.id,
                    user_id: 'return_value'
                  }
                }
              }
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @lookup_rec1
      expect { ca.calc_action_if }.not_to raise_error
      expect(ca.calc_action_if).to be true
    end
  end

  describe 'AC11: backwards compatibility — existing behaviour is unaffected' do
    it 'existing no_masters query with return_value still works' do
      conf = {
        no_masters: {},
        dynamic_model__test_no_master_dm_recs: {
          id: @dm1.id,
          data: 'return_value'
        }
      }

      ca = ConditionalActions.new conf, @dm1
      res = ca.get_this_val
      expect(res).to eq @dm1.data
    end

    it 'existing condition: IS NOT NULL without return flags still works as a filter' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            id: @dm1.id,
            data: { condition: 'IS NOT NULL' }
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect(ca.calc_action_if).to be true
    end

    it 'existing no_masters lookup using a literal value still works' do
      conf = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: @dm1.data
          }
        }
      }

      ca = ConditionalActions.new conf, @dm1
      expect(ca.calc_action_if).to be true

      conf_fail = {
        all: {
          no_masters: {},
          dynamic_model__test_no_master_dm_recs: {
            data: 'this-value-does-not-exist'
          }
        }
      }

      ca2 = ConditionalActions.new conf_fail, @dm1
      expect(ca2.calc_action_if).to be false
    end
  end
end
