module AdminActionLogging

  extend ActiveSupport::Concern

  included do
    before_action :capture_prev_value, only: [:update]
    after_action :log_admin_item_action, only: [:create, :update]

    ExcludeClasses = ['Devise::SessionsController', 'Devise::RegistrationsController']
  end

  private

    def action_log_item_type
      self.class.name.singularize.ns_underscore.sub('_controller', '')
    end

    def log_admin_item_action

      return if self.class.name.in?(ExcludeClasses)

      Admin::AdminActionLog.create! admin_id: current_admin.id, item_id: object_instance.id, item_type: action_log_item_type, action: action_name, url: request.original_fullpath,
                                    prev_value: @prev_value,
                                    new_value: object_instance.attributes
    end

    def capture_prev_value
      @prev_value = object_instance.attributes.dup
    end

end
