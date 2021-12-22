# frozen_string_literal: true

module UserActionLogging
  extend ActiveSupport::Concern

  included do
    after_action :log_user_item_action, only: %i[show create update], unless: :canceled?
    after_action :log_user_index_action, only: [:index]

    ExcludeClasses = %w[Devise::ConfirmationsController
                        Devise::SessionsController
                        Devise::RegistrationsController
                        Users::RegistrationsController].freeze
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
    master = @master

    if defined?(object_instance) && object_instance
      nma = object_instance.class.no_master_association
      master ||= object_instance.master unless nma
    else
      nma = true
    end

    master_id = master.id if master

    begin
      attrs = {
        user_id: current_user.id,
        app_type_id: current_user.app_type_id,
        master_id: master_id,
        item_id: @id,
        item_type: action_log_item_type,
        action: action_name,
        url: request.original_fullpath,
        no_master_association: nma
      }

      Admin::UserActionLog.create! attrs
    rescue StandardError => e
      Rails.logger.error "
        ****************************************************************
        *** Failed to create user action log in log_user_item_action ***
        ****************************************************************
        #{attrs}
        "
      Rails.logger.error "#{e.inspect}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end

  def log_user_index_action(force_item_type: nil)
    return if no_action_log || self.class.name.in?(ExcludeClasses) || @no_masters

    # Use rescue rather than checking respond to, since this had weird behaviors
    master = @master

    if defined?(object_instance) && object_instance
      nma = object_instance.class.no_master_association
      master ||= object_instance.master unless nma
    end

    if defined?(objects_instance) && objects_instance
      nma = objects_instance.model.no_master_association
      master ||= objects_instance.first&.master unless nma
    end

    master_id = master.id if master

    if @master_ids
      ids = @master_ids
    else
      masters = @masters || @master_objects
      ids = masters.map(&:id) if masters
    end

    ids&.reject!(&:nil?)

    action = :index
    it = force_item_type || action_log_item_type

    begin
      attrs = {
        user_id: current_user.id,
        app_type_id: current_user.app_type_id,
        master_id: master_id,
        item_type: it,
        index_action_ids: ids,
        action: action,
        url: request.original_fullpath,
        no_master_association: nma
      }

      Admin::UserActionLog.create! attrs
    rescue StandardError => e
      Rails.logger.error "
        *****************************************************************
        *** Failed to create user action log in log_user_index_action ***
        *****************************************************************
        #{attrs}
        "
      Rails.logger.error "#{e.inspect}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end

  # Overridable method. By default, action logging is enabled
  # @return [Boolean]
  #   false: enable logging
  #   true: disable logging
  def no_action_log
    false
  end
end
