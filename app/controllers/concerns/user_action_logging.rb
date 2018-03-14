module UserActionLogging

  extend ActiveSupport::Concern

  included do
    after_action :log_user_item_action, only: [:show, :create, :update]
    after_action :log_user_index_action, only: [:index]

    ExcludeClasses = ['Devise::SessionsController', 'Devise::RegistrationsController']
  end

  private

    def action_log_item_type
      self.class.name.singularize.ns_underscore.sub('_controller', '')
    end

    def log_user_item_action

      if is_a?(ReportsController) && action_name == 'show'
        log_user_index_action force_item_type: :masters
        return
      end

      return if no_action_log || self.class.name.in?(ExcludeClasses)

      # Use rescue rather than checking respond to, since this had weird behaviors
      master = @master || object_instance.master rescue nil

      master_id = master.id if master

      UserActionLog.create! user_id: current_user.id, app_type_id: current_user.app_type_id, master_id: master_id, item_id: @id, item_type: action_log_item_type, action: action_name, url: request.original_fullpath
    end

    def log_user_index_action force_item_type: nil

      return if no_action_log || self.class.name.in?(ExcludeClasses) || @no_masters

      # Use rescue rather than checking respond to, since this had weird behaviors
      master = @master || object_instance.master rescue nil

      master_id = master.id if master

      if @master_ids
        ids = @master_ids
      else
        masters = @masters || @master_objects
        ids = masters.map(&:id)
      end

      action = :index
      it = force_item_type || action_log_item_type


      UserActionLog.create! user_id: current_user.id, app_type_id: current_user.app_type_id, master_id: master_id, item_type: it, index_action_ids: ids, action: action, url: request.original_fullpath
    end


end
