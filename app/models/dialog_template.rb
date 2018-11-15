class DialogTemplate

  def self.generate_message name, item
    mt = Admin::MessageTemplate.active.dialog_templates.where(name: name).first
    raise FphsException.new "Dialog template '#{name}' not found" unless mt
    all_content = mt.template.dup
    mt.substitute all_content, data: item, tag_subs: 'em class="all_caps"'
  end
end
