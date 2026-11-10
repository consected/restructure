# frozen_string_literal: true

module UserActionLogging
  extend ActiveSupport::Concern

  included do
    after_action :log_user_item_action, only: %i[show create update], unless: :canceled?
    after_action :log_user_index_action, only: [:index]

    ExcludeClasses = %w(Devise::ConfirmationsController
                        Devise::PasswordsController
                        Devise::RegistrationsController
                        Devise::SessionsController
                        Users::RegistrationsController).freeze

  end

  private

  def action_log_item_type
    self.class.name.singularize.ns_underscore.sub('_controller', '')
  end

  # klass's no_master_association flag, or nil if klass doesn't implement it
  def no_master_association_for(klass)
    klass.no_master_association if klass.respond_to?(:no_master_association)
  end

  def log_user_item_action
    if is_a?(ReportsController) && action_name == 'show'
      log_user_index_action force_item_type: :masters
      return
    end

    return if no_action_log || self.class.name.in?(ExcludeClasses)

    master = @master
    # Default to true (no association) unless object_instance says otherwise below
    nma = true

    if defined?(object_instance) && (instance = object_instance)
      nma = no_master_association_for(instance.class)
      master ||= instance.master if !nma && instance.respond_to?(:master)
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

    master = @master
    nma = nil

    if defined?(object_instance) && (instance = object_instance)
      nma = no_master_association_for(instance.class)
      master ||= instance.master if !nma && instance.respond_to?(:master)
    end

    if defined?(objects_instance) && (instances = objects_instance)
      nma = no_master_association_for(instances.model)

      # only query for the first record when it might actually be needed
      if !nma && !master
        first = instances.first
        master = first.master if first.respond_to?(:master)
      end
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
