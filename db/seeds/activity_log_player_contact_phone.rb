# frozen_string_literal: true

module Seeds
  module ActivityLogPlayerContactPhone
    def self.add_values(values, item_type)
      values.each do |v|
        res = Classification::GeneralSelection.find_or_initialize_by(v.merge(item_type: item_type))
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_phone_log_admin_activity_log
      res = ActivityLog.where(name: 'Phone Log').first
      unless res
        res = ActivityLog.find_or_initialize_by(name: 'Phone Log', item_type: 'player_contact', rec_type: 'phone', disabled: false, action_when_attribute: 'called_when',
                                                field_list: 'data, select_call_direction, select_who, called_when, select_result, select_next_step, follow_up_when, notes, protocol_id, set_related_player_contact_rank',
                                                blank_log_field_list: 'select_who, called_when, select_next_step, follow_up_when, notes, protocol_id', process_name: '')
      end
      unless res.active_model_configuration?
        Trackers.setup
        GeneralSelections.setup

        # If this was a new item, set an admin. Also set disabled nil, since this forces regeneration of the model
        res.update!(current_admin: auto_admin) unless res.admin
        tu = User.template_user
        app_type = Admin::AppType.active.first
        # Ensure there is at least one user access control, otherwise we won't re-enable the process on future loads
        res.other_regenerate_actions
        res.add_user_access_controls force: true, app_type: app_type
      end

      res.update_tracker_events

      res
    end

    def self.create_phone_log_general_selections
      item_type = 'activity_log__player_contact_phone_select_call_direction'

      values = [
        { name: 'To Player', value: 'to player', create_with: true, lock: true },
        { name: 'To Staff', value: 'to staff', create_with: true, lock: true }
      ]

      add_values values, item_type
      Rails.logger.info "#{name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"

      item_type = 'activity_log__player_contact_phone_select_next_step'
      values = [
        { name: 'Complete', value: 'complete', create_with: true, lock: true },
        { name: 'Call Back', value: 'call back', create_with: true, lock: true },
        { name: 'No Follow Up', value: 'no follow up', create_with: true, lock: true },
        { name: 'More Info Requested', value: 'more info requested', create_with: true, lock: true }
      ]
      add_values values, item_type
      Rails.logger.info "#{name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"

      item_type = 'activity_log__player_contact_phone_select_result'
      values = [
        { name: 'Connected', value: 'connected', create_with: true, lock: true },
        { name: 'Left Voicemail', value: 'voicemail', create_with: true, lock: true },
        { name: 'Not Connected', value: 'not connected', create_with: true, lock: true },
        { name: 'Bad Number', value: 'bad number', create_with: true, lock: true }
      ]
      add_values values, item_type
      Rails.logger.info "#{name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"

      item_type = 'activity_log__player_contact_phone_select_who'
      values = [
        { name: 'User', value: 'user', create_with: true, lock: true }
      ]
      add_values values, item_type
      Rails.logger.info "#{name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end

    def self.setup
      log "In #{self}.setup"

      if Rails.env.test? || Classification::GeneralSelection.where(item_type: 'activity_log__player_contact_phone_select_call_direction').empty?
        create_phone_log_general_selections
        als = ActivityLog.where(name: 'Phone Log')
        als.update_all(disabled: true) if als.length > 1
      end

      # TODO add process name to blank
      res = ActivityLog.active.where(name: 'Phone Log').first

      res ||= create_phone_log_admin_activity_log

      if Rails.env.test?

        res.update(current_admin: auto_admin, disabled: false)

        app_type = Admin::AppType.where(name: :zeus).first
        uac = Admin::UserAccessControl.where(user: nil, app_type: app_type, resource_type: 'table', resource_name: 'activity_log__player_contact_phones').first
        if uac
          uac.update(disabled: false, current_admin: auto_admin, access: :create)
        else
          Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: 'table', resource_name: 'activity_log__player_contact_phones', access: :create, current_admin: auto_admin)
        end
      end
    end
  end
end
