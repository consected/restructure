# Support dynamic definition options specs
module OptionsSupport
  def option_configs_comparable(arr)
    return unless arr.is_a? Array

    arr.map(&:orig_config)
  end

  def check_version(num)
    # Forcefully reload unless not persisted
    inst_id = @dyn_instances[num].id
    @dyn_instances[num] = @dyn_instances[num].class.find(inst_id) if inst_id

    dyn_inst = @dyn_instances[num]
    expect(dyn_inst.class.to_s).to eq dynamic_type

    t = dyn_inst.options_text
    expect(t).to eq @option_texts[num]
    expect(dyn_inst.versioned_definition.updated_at.to_i).to eq @def_updated_at[num].to_i

    prev_updated = @def_updated_at[num - 1]
    expect(dyn_inst.updated_at).to be > prev_updated if prev_updated && num > 0

    next_updated = @def_updated_at[num + 1]
    expect(dyn_inst.updated_at).to be < next_updated if next_updated

    expect(option_configs_comparable(dyn_inst.versioned_definition.option_configs)).to eql option_configs_comparable(@option_configs[num])
    expect(option_configs_comparable(dyn_inst.versioned_definition.option_configs(force: true))).to eql option_configs_comparable(@option_configs[num])
  end
end
