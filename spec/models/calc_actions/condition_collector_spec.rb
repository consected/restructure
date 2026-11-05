# frozen_string_literal: true

# Verifies that CalcActions::ConditionCollector finds every condition and value configuration that the runtime
# evaluates within an option type or a page layout's perspectives, with its path and linter mode. Trigger types
# declare the keys holding conditions, values and nested task lists through the TriggerTypes DSL.
require 'rails_helper'

RSpec.describe CalcActions::ConditionCollector, type: :model do
  let(:cond) { { all: { addresses: { city: 'portland' } } } }
  let(:value) { { all: { addresses: { city: 'portland', zip: 'return_value' } } } }

  def collect(configuration = nil, path: 'default', **options)
    described_class.collect(configuration: configuration || options, path:, model_class: Master)
  end

  def paths_of(entries) = entries.map { |entry| entry[:path] }

  it 'collects option-level conditions' do
    entries = collect(creatable_if: cond, editable_if: cond, showable_if: cond, add_reference_if: cond)

    expect(paths_of(entries)).to contain_exactly('default.creatable_if', 'default.editable_if',
                                                 'default.showable_if', 'default.add_reference_if')
    expect(entries).to all(include(mode: :condition, condition: cond, model_class: Master))
  end

  it 'collects valid_if conditions for each trigger' do
    entries = collect(valid_if: { on_save: cond, on_create: cond, on_update: cond })

    expect(paths_of(entries)).to contain_exactly('default.valid_if.on_save', 'default.valid_if.on_create',
                                                 'default.valid_if.on_update')
  end

  it 'collects reference conditions and add_with values' do
    entries = collect(references: { addresses: { showable_if: cond, add_with: { city: value, extra_log_type: 'x' } } })

    expect(entries).to include(a_hash_including(path: 'default.references.addresses.showable_if', mode: :condition))
    expect(entries).to include(a_hash_including(path: 'default.references.addresses.add_with.city', mode: :value))
    expect(paths_of(entries)).not_to include('default.references.addresses.add_with.extra_log_type')
  end

  it 'collects save_action if conditions by lifecycle and action' do
    entries = collect(save_action: { on_save: { notify_me: { if: cond, value: 'x' } } })

    expect(paths_of(entries)).to eq(['default.save_action.on_save.notify_me.if'])
  end

  it 'collects set_variables if conditions and values' do
    entries = collect(set_variables: [{ name: 'x', if: cond, value: value }])

    expect(paths_of(entries)).to contain_exactly('default.set_variables[0].if', 'default.set_variables[0].value')
  end

  it 'exposes the structured path keys of each entry, with list indexes as integers' do
    entries = collect(set_variables: [{ name: 'x', if: cond, value: value }])

    expect(entries).to include(a_hash_including(path_keys: ['default', 'set_variables', 0, 'if'], mode: :condition))
    expect(entries).to include(a_hash_including(path_keys: ['default', 'set_variables', 0, 'value'], mode: :value))
  end

  it 'collects nfs_store can conditions ending in _if' do
    entries = collect(nfs_store: { can: { download_if: cond, view_files_as_html: 'x' } })

    expect(paths_of(entries)).to eq(['default.nfs_store.can.download_if'])
  end

  it 'collects save trigger tasks, including nested each, case, transaction and background tasks' do
    entries = collect(save_trigger: {
                        before_save: [
                          { update_reference: { if: cond, first: value, with: { address: value, city: 'literal' } } }
                        ],
                        on_create: [
                          { each: { value: '{{x}}', do: [{ set_variables: { if: cond, value: value } }] } },
                          { case: [{ when: cond, then: [{ log: { message: 'x' } }] },
                                   { else: [{ update_this: { with: { city: value } } }] }] },
                          { transaction: [{ set_variables: { if: cond } }] },
                          { background: [{ run_batch_trigger: { if: cond } }] }
                        ]
                      })

    expect(paths_of(entries)).to contain_exactly(
      'default.save_trigger.before_save[0].update_reference.if',
      'default.save_trigger.before_save[0].update_reference.first',
      'default.save_trigger.before_save[0].update_reference.with.address',
      'default.save_trigger.on_create[0].each.do[0].set_variables.if',
      'default.save_trigger.on_create[0].each.do[0].set_variables.value',
      'default.save_trigger.on_create[1].case[0].when',
      'default.save_trigger.on_create[1].case[1].else[0].update_this.with.city',
      'default.save_trigger.on_create[2].transaction[0].set_variables.if',
      'default.save_trigger.on_create[3].background[0].run_batch_trigger.if'
    )
  end

  it 'collects batch trigger on_record tasks and config trigger on_define tasks' do
    entries = collect(batch_trigger: { on_record: [{ run_batch_trigger: { if: cond, mode: 'x' } }] },
                      config_trigger: { on_define: [{ create_defaults: {} }] })

    expect(paths_of(entries)).to eq(['default.batch_trigger.on_record[0].run_batch_trigger.if'])
  end

  it 'does not treat with: embedded_item values as conditions, as they are evaluated one by one' do
    entries = collect(save_trigger: { on_create: [{ create_reference: { in: 'master', with: {
                        embedded_item: { select_related_study: '{{biodata_participants.study}}' },
                        extra_log_type: { one: 'x' }
                      } } }] })

    expect(paths_of(entries)).to eq(['default.save_trigger.on_create[0].create_reference.with.extra_log_type'])
  end

  it 'collects with: values for each trigger that uses the shared with: evaluation' do
    entries = collect(save_trigger: { on_save: [{ update_this: { with: { addresses: value } } }] })

    expect(paths_of(entries)).to eq(['default.save_trigger.on_save[0].update_this.with.addresses'])
  end

  it 'collects page layout perspective conditional_calculation values with no_masters injected' do
    entries = described_class.collect(
      configuration: { view_options: { perspectives: { addresses: [{ name: 'open', conditional_calculation: {
        addresses: { city: 'portland', return: 'return_all_results' }
      } }] } } },
      path: '',
      model_class: nil
    )

    expect(entries).to contain_exactly(a_hash_including(
                                         path: 'view_options.perspectives.addresses[0].conditional_calculation',
                                         mode: :value
                                       ))
    expect(entries.first[:condition]).to include(:no_masters)
  end

  it 'does not collect scalar values, which are not evaluated as conditions' do
    entries = collect(save_trigger: { on_save: [{ set_variables: { name: 'x', value: 'literal' } }] })

    expect(entries).to be_empty
  end

  describe 'implied no_masters' do
    def perspective_entries(calc)
      described_class.collect(
        configuration: { view_options: { perspectives: { addresses: [{ conditional_calculation: calc }] } } },
        path: '',
        model_class: nil
      )
    end

    it 'flags the no_masters injected into a perspective conditional_calculation as implied' do
      expect(perspective_entries({ addresses: { city: 'portland' } })).to contain_exactly(
        a_hash_including(mode: :value, implied_no_masters: true)
      )
    end

    it 'does not flag a no_masters that the admin wrote into a perspective conditional_calculation' do
      expect(perspective_entries({ no_masters: { addresses: {} }, addresses: { city: 'portland' } })).to contain_exactly(
        a_hash_including(implied_no_masters: false)
      )
    end

    it 'does not flag conditions or values outside perspective conditional_calculation' do
      entries = collect(creatable_if: cond, save_trigger: { on_save: [{ update_this: { with: { city: value } } }] })

      expect(entries.length).to eq(2)
      expect(entries).to all(include(implied_no_masters: false))
    end
  end

  describe 'trigger type descriptors' do
    let(:base) { OptionConfigs::TriggerTypes::Base }

    it 'declares condition keys, including the standard if: and additional conditions' do
      expect(base.for(:update_reference).condition_keys).to include(:if)
      expect(base.for(:pull_external_data).condition_keys).to include(:if, :success_if)
      expect(base.for(:case).condition_keys).to include(:when)
    end

    it 'declares value keys, distinguishing single values from maps of field values' do
      expect(base.for(:update_reference).value_keys).to include(:first)
      expect(base.for(:update_reference).value_map_keys).to include(:with)
      expect(base.for(:set_variables).value_keys).to include(:value)
    end

    it 'declares nested task keys, including lifecycle hooks on every trigger type' do
      expect(base.for(:each).task_keys).to include(:do, :on_complete, :on_failure)
      expect(base.for(:case).task_keys).to include(:then, :else)
      expect(base.for(:transaction).task_list_config?).to be(true)
      expect(base.for(:update_reference).task_list_config?).to be(false)
    end
  end
end
