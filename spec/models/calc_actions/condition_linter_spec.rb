# frozen_string_literal: true

# Verifies that CalcActions::ConditionLinter reports problems that would otherwise only fail at runtime,
# and that valid configurations (including those documented in the conditions reference) produce no notices.
# Each check has a valid and an invalid example. Notices are { path:, message: } warnings.
require 'rails_helper'

RSpec.describe CalcActions::ConditionLinter, type: :model do
  def lint(condition, mode: :condition, model_class: Master, implied_no_masters: false)
    described_class.new(condition:, path: 'options.default.showable_if', model_class:, mode:,
                        implied_no_masters:).lint
  end

  # The offending path or message must name the problem, so administrators can find it
  def expect_notice(condition, mentioning:, **)
    notices = lint(condition, **)

    expect(notices).not_to be_empty
    expect(notices).to all(include(:path, :message))
    expect(notices.map { |n| "#{n[:path]} #{n[:message]}" }).to include(a_string_including(mentioning))
  end

  def expect_clean(condition, **)
    expect(lint(condition, **)).to be_empty
  end

  describe 'top-level keys' do
    it 'accepts selection types with suffixes, always, never and shortcuts' do
      expect_clean({ all: { addresses: { city: 'portland' } } })
      expect_clean({ all_2: { addresses: { city: 'portland' } }, not_any_cancelled: { addresses: { city: 'x' } } })
      expect_clean({ always: true })
      expect_clean({ has_created_activity: 'primary' })
    end

    it 'rejects unrecognized top-level keys' do
      expect_notice({ contains: { addresses: { city: 'portland' } } }, mentioning: 'contains')
    end

    it 'rejects a table at the top level of a condition, which the runtime cannot evaluate' do
      expect_notice({ addresses: { city: 'portland' } }, mentioning: 'addresses')
    end

    it 'allows a table at the top level of a value configuration' do
      expect_clean({ addresses: { city: 'portland', zip: 'return_value' } }, mode: :value)
    end
  end

  describe 'record sources (tables)' do
    it 'accepts special sources, masters, users and associations of masters' do
      expect_clean({ all: { masters: {}, users: { email: { user: 'email' } }, this: { id: 1 } } })
      expect_clean({ all: { activity_log__player_contact_phones: { select_who: 'user' } } })
      expect_clean({ all: { player_infos_item_flags: { item_id: { this: 'id' } } } })
    end

    it 'rejects tables that are neither associations of masters nor no_masters resources' do
      expect_notice({ all: { missing_association: { id: 1 } } }, mentioning: 'missing_association')
    end

    it 'rejects reserved keys used as record sources' do
      expect_notice({ all: { this_references: { id: 1 } } }, mentioning: 'this_references')
    end
  end

  describe 'no_masters base table' do
    it 'accepts a known resource as the base table' do
      expect_clean({ all: { no_masters: {}, addresses: { city: 'portland' } } })
    end

    it 'rejects an unknown base table' do
      expect_notice({ all: { no_masters: {}, missing_base_table: { id: 1 } } }, mentioning: 'missing_base_table')
    end

    it 'locates an unknown base table at the table itself, which is part of the configuration' do
      notices = lint({ all: { no_masters: {}, missing_base_table: { id: 1 } } })

      expect(notices).to contain_exactly(a_hash_including(
                                           path_keys: %w[options default showable_if all missing_base_table]
                                         ))
    end

    it 'rejects no_masters without any table to act as the base' do
      expect_notice({ all: { no_masters: {} } }, mentioning: 'no_masters')
    end

    it 'locates no_masters without a base table at the block that holds it' do
      notices = lint({ all: { no_masters: {} } })

      expect(notices).to contain_exactly(a_hash_including(path_keys: %w[options default showable_if all]))
    end
  end

  # A page layout perspective conditional_calculation has no_masters: {} injected at runtime, so the admin may not
  # have written it. The messages must then describe the perspective, rather than refer to no_masters.
  describe 'no_masters implied by a perspective' do
    let(:unknown_base) { { no_masters: {}, activity_log__somethins: { 'do nothing': true } } }

    def messages(notices) = notices.map { |notice| notice[:message] }

    it 'describes the perspective base without mentioning no_masters when the perspective implied it' do
      notices = lint(unknown_base, mode: :value, implied_no_masters: true)

      expect(messages(notices)).to contain_exactly(
        "'activity_log__somethins' is not a known resource. A perspective conditional_calculation must start " \
        'from an activity log, dynamic model or other resource'
      )
    end

    it 'keeps the no_masters wording when the admin wrote no_masters' do
      notices = lint(unknown_base, mode: :value)

      expect(messages(notices)).to contain_exactly(
        "'activity_log__somethins' is not a known resource to use as the base of a no_masters: {} query"
      )
    end

    it 'says an empty perspective needs a resource, without mentioning no_masters, when the perspective implied it' do
      notices = lint({ no_masters: {} }, mode: :value, implied_no_masters: true)

      expect(messages(notices)).to contain_exactly(a_string_including('needs a resource'))
      expect(messages(notices).join).not_to include('no_masters')
    end

    it 'keeps the no_masters wording for an empty no_masters block that the admin wrote' do
      notices = lint({ no_masters: {} }, mode: :value)

      expect(messages(notices)).to contain_exactly(a_string_including('no_masters: {} needs a table'))
    end

    it 'applies the implied wording only to the perspective block, not to a no_masters the admin wrote within it' do
      condition = { no_masters: {}, addresses: { city: 'portland' }, all: { no_masters: {} } }
      notices = lint(condition, mode: :value, implied_no_masters: true)

      expect(notices).to contain_exactly(a_hash_including(
                                           path_keys: %w[options default showable_if all],
                                           message: a_string_including('no_masters: {} needs a table')
                                         ))
    end
  end

  describe 'field names' do
    it 'accepts fields known to the associated model and to this record' do
      expect_clean({ all: { addresses: { city: 'portland', zip: '12345' } } })
      expect_clean({ all: { this: { id: 1, created_at: { condition: 'IS NOT NULL' } } } })
    end

    it 'rejects fields that are not known to the associated model' do
      expect_notice({ all: { addresses: { field_that_does_not_exist: 'x' } } }, mentioning: 'field_that_does_not_exist')
    end

    it 'rejects fields that are not known to this record' do
      expect_notice({ all: { this: { field_that_does_not_exist: 'x' } } }, mentioning: 'field_that_does_not_exist')
    end

    it 'does not check the return pseudo-field or special fields' do
      expect_clean({ all: { addresses: { city: 'portland', return: 'return_result' } } })
      expect_clean({ all: { addresses: { return_constant: 'x' } } })
      expect_clean({ all: { addresses: { exists: true } } })
    end

    it 'accepts protocol, sub process and protocol event names on tracker_history' do
      expect_clean({ all: { no_masters: {}, tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                                               protocol_event_name: 'Error' } } })
    end

    it 'does not accept protocol, sub process or protocol event names on other tables' do
      expect_notice({ all: { no_masters: {}, addresses: { protocol_name: 'P1' } } }, mentioning: 'protocol_name')
      expect_notice({ all: { addresses: { sub_process_name: 'Information' } } }, mentioning: 'sub_process_name')
      expect_notice({ all: { no_masters: {}, addresses: { protocol_event_name: 'Error' } } },
                    mentioning: 'protocol_event_name')
    end

    it 'checks the field name when the value is a return keyword' do
      expect_notice({ all: { addresses: { city_typo: 'return_value' } } }, mentioning: 'city_typo', mode: :value)
      expect_notice({ all: { masters: { mssid: 'return_value' } } }, mentioning: 'mssid', mode: :value)
      expect_notice({ all: { this: { field_that_does_not_exist: 'return_value' } } },
                    mentioning: 'field_that_does_not_exist', mode: :value)
    end

    it 'accepts a return keyword for a field known to the model' do
      expect_clean({ all: { addresses: { city: 'return_value' } } }, mode: :value)
      expect_clean({ all: { masters: { msid: 'return_value' } } }, mode: :value)
    end

    it 'does not check fields of record sources whose model is only known at runtime' do
      expect_clean({ all: { referring_record: { select_who: 'user' } } })
    end
  end

  describe 'operators' do
    it 'accepts database operators on database tables' do
      expect_clean({ all: { addresses: { city: { condition: 'ILIKE', value: 'PORT%' } } } })
    end

    it 'accepts in-memory operators on this record' do
      expect_clean({ all: { this: { id: { condition: '==', value: 1 } } } })
      expect_clean({ all: { this: { id: { condition: 'in?', value: [1, 2] } } } })
    end

    it 'rejects in-memory-only operators on database tables' do
      expect_notice({ all: { addresses: { city: { condition: '==', value: 'Portland' } } } },
                    mentioning: '==')
    end

    it 'rejects database-only operators on this record' do
      expect_notice({ all: { this: { id: { condition: 'LIKE', value: '1%' } } } }, mentioning: 'LIKE')
    end

    it 'rejects unknown operators' do
      expect_notice({ all: { addresses: { city: { condition: 'approx', value: 'x' } } } }, mentioning: 'approx')
    end

    it 'requires a value for binary and array operators' do
      expect_notice({ all: { addresses: { city: { condition: '= ANY' } } } }, mentioning: 'city')
      expect_clean({ all: { addresses: { city: { condition: '= ANY', value: ['Portland'] } } } })
    end

    it 'allows unary operators without a value' do
      expect_clean({ all: { addresses: { city: { condition: 'IS NOT NULL' } } } })
    end

    it 'rejects an unsupported operator once, without also requiring a value' do
      notices = lint({ all: { this: { id: { condition: 'NOT NULL' } } } })

      expect(notices.length).to eq(1)
      expect(notices.first[:message]).to include("condition 'NOT NULL' is not supported")
    end

    it 'rejects a top-level this: key, which has no selection type' do
      expect_notice({ this: { id: 1 } }, mentioning: 'this')
    end

    it 'rejects unrecognized keys alongside a condition, such as a typo' do
      expect_notice({ all: { addresses: { city: { condition: '=', valu: 'x' } } } }, mentioning: 'valu')
    end
  end

  describe 'return flags' do
    it 'accepts a single return flag alongside a condition' do
      expect_clean({ all: { addresses: { city: { condition: 'IS NOT NULL', return_value: true } } } })
    end

    it 'rejects more than one return flag' do
      expect_notice(
        { all: { addresses: { city: { condition: 'IS NOT NULL', return_value: true, return_result: true } } } },
        mentioning: 'city'
      )
    end

    it 'rejects a return flag without a condition' do
      expect_notice({ all: { addresses: { city: { return_value: true } } } }, mentioning: 'return_value')
    end
  end

  describe 'return keywords' do
    it 'accepts the return keywords' do
      expect_clean({ all: { addresses: { city: 'return_value_list' } } }, mode: :value)
    end

    it 'accepts literal values that start with return_ but are not close to a return keyword' do
      expect_clean({ all: { addresses: { city: 'return_call' } } })
      expect_clean({ all: { addresses: { city: 'return_call' } } }, mode: :value)
      expect_clean({ all: { addresses: { city: 'return_the_whole_database' } } }, mode: :value)
    end

    it 'warns about a likely typo of a return keyword' do
      %w[return_val return_results return_values retrun_value].each do |typo|
        expect_notice({ all: { addresses: { city: typo } } }, mentioning: typo, mode: :value)
      end
    end
  end

  describe 'calculate' do
    it 'accepts supported functions over attributes of this record' do
      expect_clean({ all: { this: { calculate: { count_not_null: { attributes: %i[id created_at] } } } } },
                   mode: :value)
    end

    it 'rejects unsupported calculate functions' do
      expect_notice({ all: { this: { calculate: { median: { attributes: %i[id created_at] } } } } },
                    mentioning: 'median', mode: :value)
    end

    it 'rejects attributes that are not fields of this record' do
      expect_notice({ all: { this: { calculate: { sum: { attributes: %i[not_a_field] } } } } },
                    mentioning: 'not_a_field', mode: :value)
    end
  end

  describe 'validators' do
    it 'accepts known validators' do
      expect_clean({ all: { addresses: { city: { validate: { min_length: 2 } } } } })
    end

    it 'rejects unknown validators' do
      expect_notice({ all: { addresses: { city: { validate: { bogus_validator: 2 } } } } },
                    mentioning: 'bogus_validator')
    end
  end

  describe 'lookup' do
    let(:valid_lookup) do
      { all: { addresses: { zip: { lookup: { all: { masters: {}, addresses: { city: 'Portland', zip: 'return_value' } } } } } } }
    end

    it 'accepts a sub-query returning a value' do
      expect_clean(valid_lookup, mode: :value)
    end

    it 'rejects a lookup that is not a condition hash' do
      expect_notice({ all: { addresses: { zip: { lookup: 'not a condition hash' } } } }, mentioning: 'lookup',
                                                                                         mode: :value)
    end

    it 'rejects a lookup that returns records rather than values' do
      lookup = { all: { addresses: { city: 'Portland', return: 'return_result' } } }
      expect_notice({ all: { addresses: { zip: { lookup: lookup } } } }, mentioning: 'return_result', mode: :value)
    end

    it 'rejects a lookup that requests no return value' do
      lookup = { all: { addresses: { city: 'Portland' } } }
      expect_notice({ all: { addresses: { zip: { lookup: lookup } } } }, mentioning: 'lookup', mode: :value)
    end
  end

  describe 'reference traversal' do
    it 'accepts this_references with an attribute name, or a record type and attribute' do
      expect_clean({ all: { addresses: { id: { this_references: 'id' } } } })
      expect_clean({ all: { addresses: { rank: { this_references: { address: 'rank' } } } } })
    end

    it 'rejects this_references naming more than one record type' do
      expect_notice({ all: { addresses: { rank: { this_references: { address: 'rank', other: 'rank' } } } } },
                    mentioning: 'this_references')
    end

    it 'accepts ids_referencing with a target and a from block returning all results' do
      from = { activity_log__player_contact_phones: { select_who: 'user', return: 'return_all_results' } }
      expect_clean({ all: { addresses: { id: { ids_referencing: { target: { addresses: { city: 'x' } }, from: } } } } })
    end

    it 'rejects ids_referencing without a target' do
      expect_notice({ all: { addresses: { id: { ids_referencing: { from: 'addresses' } } } } },
                    mentioning: 'ids_referencing')
    end

    it 'rejects an ids_referencing from block that does not return all results' do
      from = { addresses: { city: 'x' } }
      expect_notice({ all: { addresses: { id: { ids_referencing: { target: { addresses: {} }, from: } } } } },
                    mentioning: 'return_all_results')
    end
  end

  describe 'database conditions within any and not_any' do
    it 'accepts database conditions directly within an all block' do
      expect_clean({ all: { addresses: { rank: { condition: '>', value: 5 } } } })
    end

    it 'rejects database conditions directly within any or not_any blocks' do
      expect_notice({ any: { addresses: { rank: { condition: '>', value: 5 } } } }, mentioning: '>')
      expect_notice({ not_any: { addresses: { rank: { condition: '>', value: 5 } } } }, mentioning: '>')
    end

    it 'accepts database conditions within an all block nested inside an any block' do
      expect_clean({ any: { all_matching: { addresses: { rank: { condition: '>', value: 5 } } } } })
    end

    it 'accepts in-memory conditions within any blocks' do
      expect_clean({ any: { this: { id: { condition: '>', value: 0 } } } })
    end
  end

  describe 'nested selection types' do
    it 'accepts blocks nested within a block' do
      expect_clean({ all: { addresses: { city: 'portland' }, any_city: { addresses: { city: 'portland' } } } })
    end

    it 'checks nested blocks recursively' do
      expect_notice({ all: { any_city: { missing_nested_table: { id: 1 } } } }, mentioning: 'missing_nested_table')
    end

    it 'accepts a list of blocks for a selection type' do
      expect_clean({ any_matching_address: [{ addresses: { zip: '12345' } }, { addresses: { zip: 'no such zip' } }] })
    end
  end

  describe 'value configurations' do
    it 'lints from the supplied path, so notices identify the configuration location' do
      notices = lint({ all: { missing_value_table: { id: 'return_value' } } },
                     mode: :value)

      expect(notices).not_to be_empty
      expect(notices.map { |n| n[:path].to_s }).to include(a_string_including('missing_value_table'))
    end

    it 'accepts first: style values without a top-level selection type' do
      expect_clean({ addresses: { city: 'portland', zip: 'return_value' } }, mode: :value)
    end

    it 'ignores the object pass-through form used for JSON values' do
      expect_clean({ object: { any: 'value' } }, mode: :value)
    end
  end

  describe 'notice locations' do
    it 'exposes the location as structured path keys, from the top-level key to the offending key' do
      notices = lint({ all: { masters: { mssid: 'x' } } })

      expect(notices).to contain_exactly(a_hash_including(
                                           path_keys: %w[options default showable_if all masters mssid],
                                           path: 'options.default.showable_if.all.masters.mssid'
                                         ))
    end

    it 'keeps list indexes as integers within the path keys' do
      notices = lint({ all: [{ masters: { mssid: 'x' } }, { masters: { mssid: 'y' } }] })

      expect(notices.map { |n| n[:path_keys].last(3) }).to eq([[0, 'masters', 'mssid'], [1, 'masters', 'mssid']])
    end

    it 'keeps the location out of the message, which states only the problem' do
      notices = lint({ all: { masters: { mssid: 'x' } } })

      expect(notices.first[:message]).to include("'mssid' is not a field of")
      expect(notices.first[:message]).not_to include('options.default')
    end

    it 'accepts the prefix path as structured path keys' do
      notices = described_class.new(condition: { all: { masters: { mssid: 'x' } } },
                                    path: %w[default creatable_if], model_class: Master).lint

      expect(notices).to contain_exactly(a_hash_including(
                                           path_keys: %w[default creatable_if all masters mssid]
                                         ))
    end
  end

  describe 'robustness' do
    it 'reports a condition that is not a hash' do
      expect_notice('not a hash', mentioning: 'Hash')
    end

    it 'reports nothing for an absent condition' do
      expect_clean(nil)
    end
  end
end
