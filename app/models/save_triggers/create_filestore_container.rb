class CreateFilestoreContainer::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def if_extras: {}
    {
      name: 'general name',
      label: 'human name',
      set_default_roles: {
        role_name: {
          dir_permissions: 'rwx',
          file_permissions: 'r'
        }
      },
      if: if_extras
    }
  end

  def initialize config, item
    super

    @name = config[:name]
    @label = config[:label]
    @set_default_roles = config[:set_default_roles]

  end

  def perform
    NfsStore::Manage::Container.create_in_current_app name: @name
  end


end
