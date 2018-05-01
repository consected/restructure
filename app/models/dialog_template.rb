class DialogTemplate

  def self.generate_message name, item
    data = item.attributes.dup

    # if the referenced item has its own referenced item (much like an activity log might), then get it
    if item.respond_to?(:item) && item.item.respond_to?(:attributes)
      data[:item] = item.item.attributes
    end

    if item.respond_to?(:user) && item.user
      data[:user_email] = item.user.email
    end

    if item.respond_to?(:current_user) && item.current_user
      data[:user_email] ||= item.current_user.email
    end

    data[:player_info] = item.master.player_infos.first.attributes

    mt = MessageTemplate.active.dialog_templates.where(name: name).first
    raise FphsException.new "Dialog template '#{name}' not found" unless mt
    all_content = mt.template.dup
    mt.substitute all_content, data: data, tag_subs: 'em class="all_caps"'
  end
end
