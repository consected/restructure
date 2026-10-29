# frozen_string_literal: true

module Messaging
  class MessageNotificationTracker
    EVENT_NAMES = { 'complete' => 'Sent', 'failed' => 'Failed' }.freeze

    def self.create_for(notification)
      new(notification).create
    end

    def initialize(notification)
      @notification = notification
    end

    def create
      event_name = EVENT_NAMES[@notification.status]
      return unless event_name

      protocol = Classification::Protocol.active.find_by(name: 'General')
      sub_process = protocol && protocol.sub_processes.active.find_by(name: 'Notification')
      protocol_event = sub_process && sub_process.protocol_events.active.find_by(name: event_name)

      unless protocol && sub_process && protocol_event
        Rails.logger.warn 'Unable to create notification tracker entry: ' \
                          "General/Notification/#{event_name} was not found"
        return
      end

      tracker_targets.each do |master_id, recipients|
        create_tracker_history(master_id, recipients, protocol, sub_process, protocol_event)
      end
    rescue StandardError => e
      Rails.logger.warn "Unable to create notification tracker entry for #{@notification.id}: #{e.class}: #{e.message}"
    end

    private

    def tracker_targets
      addresses = recipient_addresses
      return { @notification.master_id => addresses } if @notification.master_id.present?
      return {} if addresses.empty?

      rec_type = @notification.sms? ? 'phone' : 'email'
      resource_name = matching_configuration[:contact_resources].fetch(rec_type)
      relation = contact_relation(resource_name, rec_type)
      return {} unless relation

      contacts = if rec_type == 'phone'
                   phone_contacts(relation, addresses)
                 else
                   email_contacts(relation, addresses)
                 end
      matches_by_master = Hash.new { |hash, key| hash[key] = [] }
      contacts.each do |master_id, recipient|
        next if master_id.nil?

        matches_by_master[master_id] << recipient unless matches_by_master[master_id].include?(recipient)
      end

      matches_by_master.transform_values do |matched_addresses|
        addresses.select { |address| matched_addresses.include?(address) }
      end
    end

    def email_contacts(relation, addresses)
      recipients_by_email = addresses.group_by(&:downcase)
      relation.where(data: recipients_by_email.keys).pluck(:master_id, :data).flat_map do |master_id, data|
        Array(recipients_by_email[data.to_s.downcase]).map { |recipient| [master_id, recipient] }
      end
    end

    def phone_contacts(relation, addresses)
      configuration = matching_configuration
      matcher = PhoneNumberMatcher.new(country_code: configuration[:country_code],
                                       trunk_number: configuration[:trunk_number])
      candidates_by_recipient = addresses.to_h { |recipient| [recipient, matcher.candidates(recipient)] }
      candidates = candidates_by_recipient.values.flatten.uniq
      return [] if candidates.empty?

      digits = Arel::Nodes::NamedFunction.new(
        'regexp_replace',
        [relation.klass.arel_table[:data],
         Arel::Nodes.build_quoted('[^0-9]'),
         Arel::Nodes.build_quoted(''),
         Arel::Nodes.build_quoted('g')]
      )
      relation.where(digits.in(candidates)).pluck(:master_id, :data).flat_map do |master_id, data|
        contact_digits = data.to_s.gsub(/[^0-9]/, '')
        candidates_by_recipient.filter_map do |recipient, recipient_candidates|
          [master_id, recipient] if recipient_candidates.include?(contact_digits)
        end
      end
    end

    def contact_relation(resource_name, rec_type)
      reflection = Master.reflect_on_association(resource_name)
      klass = reflection&.klass
      required_columns = %w[master_id data rec_type]
      valid = reflection&.macro == :has_many && klass.respond_to?(:columns_hash) &&
              (required_columns - klass.column_names).empty?
      unless valid
        Rails.logger.warn "Unable to match notification recipients: invalid contact resource #{resource_name.inspect}"
        return
      end

      relation = klass.unscoped
      relation = relation.instance_exec(&reflection.scope) if reflection.scope
      relation = relation.where(disabled: [false, nil]) if klass.column_names.include?('disabled')
      relation.where(rec_type:)
    rescue StandardError => e
      Rails.logger.warn "Unable to match notification recipients using contact resource #{resource_name.inspect}: " \
                        "#{e.class}: #{e.message}"
      nil
    end

    def matching_configuration
      @matching_configuration ||= begin
        resources = configured_contact_resources
        {
          contact_resources: {
            'email' => resources['email'].presence || 'player_contact_emails',
            'phone' => resources['phone'].presence || 'player_contact_phones'
          },
          country_code: configured_phone_digits(:default_phone_country_code, Settings::DefaultPhoneCountryCode),
          trunk_number: configured_phone_digits(:default_phone_trunk_number, Settings::DefaultPhoneTrunkNumber)
        }
      end
    end

    def configured_contact_resources
      value = app_configuration_value(:message_notification_contact_resources)
      return {} if value.blank?

      resources = YAML.safe_load(value, permitted_classes: [Symbol]) || {}
      unless resources.is_a?(Hash)
        Rails.logger.warn 'Unable to read message notification contact resources: expected a YAML hash'
        return {}
      end

      resources.transform_keys(&:to_s)
    rescue Psych::Exception => e
      Rails.logger.warn "Unable to read message notification contact resources: #{e.class}: #{e.message}"
      {}
    end

    def configured_phone_digits(name, default)
      value = app_configuration_value(name)
      digits = value.to_s.delete_prefix('+').gsub(/[^0-9]/, '')
      digits.presence || default
    end

    def app_configuration_value(name)
      return if @notification.app_type_id.blank?

      Admin::AppConfiguration
        .where(name: Admin::AppConfiguration.sym_to_name(name))
        .scope_user_and_role(@notification.user, @notification.app_type_id)
        .first&.value
    end

    def recipient_addresses
      values = if @notification.recipient_hash_from_data
                 @notification.recipient_hash_from_data.filter_map { |recipient| recipient[:data] }
               elsif @notification.sms?
                 @notification.recipient_sms_numbers
               else
                 @notification.recipient_emails
               end

      Array(values).filter_map { |value| value.to_s if value.present? }.uniq
    end

    def create_tracker_history(master_id, recipients, protocol, sub_process, protocol_event)
      tracker = Master.find(master_id).trackers.build(
        protocol_id: protocol.id,
        sub_process_id: sub_process.id,
        protocol_event_id: protocol_event.id,
        event_date: @notification.updated_at,
        notes: tracker_notes(recipients),
        item: @notification
      )
      tracker[:user_id] = @notification.user_id
      tracker.force_save!
      tracker.save!
    end

    def tracker_notes(recipients)
      notes = ["type: #{@notification.message_type}"]
      notes << "to: #{recipients.join(', ')}" if recipients.any?
      notes << "subject: #{@notification.subject}" if @notification.subject.present?
      notes.join("\n")
    end
  end
end
