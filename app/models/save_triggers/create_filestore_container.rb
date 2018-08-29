class SaveTriggers::CreateFilestoreContainer < SaveTriggers::SaveTriggersBase

  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def if_extras: {}
    {
      name: 'general name',
      label: 'human name',
      create_with_role: 'role name',
      if: if_extras
    }
  end

  def initialize config, item
    super

    @name = config[:name]
    @label = config[:label]
    @create_with_role = config[:create_with_role]
    

  end

  def perform

    container = NfsStore::Manage::Container.create_in_current_app user: item.master_user, name: @name, extra_params: {master: item.master, create_with_role: @create_with_role}
    ModelReference.create_with item, container
  end


end
