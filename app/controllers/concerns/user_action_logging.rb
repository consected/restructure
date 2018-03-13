module UserActionLogging

  extend ActiveSupport::Concern

  included do
    after_action :log_user_item_action, only: [:show, :create, :update]
    after_action :log_user_index_action, only: [:index]

    ExcludeClasses = ['Devise::SessionsController']
  end

  private

    def action_log_item_type
      self.class.name.singularize.ns_underscore.sub('_controller', '')
    end

    def log_user_item_action

      return if no_action_log || self.class.name.in?(ExcludeClasses)

      # Use rescue rather than checking respond to, since this had weird behaviors
      master = @master || object_instance.master rescue nil

      master_id = master.id if master

      UserActionLog.create! user_id: current_user.id, app_type_id: current_user.app_type_id, master_id: master_id, item_id: @id, item_type: action_log_item_type, action: action_name
    end

    def log_user_index_action

      return if no_action_log || self.class.name.in?(ExcludeClasses) || @no_masters

      # Use rescue rather than checking respond to, since this had weird behaviors
      master = @master || object_instance.master rescue nil

      master_id = master.id if master 

      masters = @masters || @master_objects
      byebug unless masters
      ids = masters.map(&:id)


      UserActionLog.create! user_id: current_user.id, app_type_id: current_user.app_type_id, master_id: master_id, item_type: action_log_item_type, index_action_ids: ids, action: action_name
    end


end
