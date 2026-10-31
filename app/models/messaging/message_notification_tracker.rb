# frozen_string_literal: true

module Messaging
  class MessageNotificationTracker
    EVENT_NAMES = { 'complete' => 'Sent', 'failed' => 'Failed' }.freeze
    Result = Struct.new(:created, :skipped, :failed, :errors, keyword_init: true)

    class TargetCreationError < StandardError
      attr_reader :result

      def initialize(result)
        @result = result
        super("Unable to create #{result.failed} notification tracker target(s)")
      end
    end

    def self.create_for(notification, skip_existing: false, strict: false)
      new(notification).create(skip_existing:, strict:)
    end

    def initialize(notification)
      @notification = notification
    end

    def create(skip_existing: false, strict: false)
      result = Result.new(created: 0, skipped: 0, failed: 0, errors: [])
      event_name = EVENT_NAMES[@notification.status]
      return result unless event_name

      protocol = Classification::Protocol.active.find_by(name: 'General')
      sub_process = protocol && protocol.sub_processes.active.find_by(name: 'Notification')

      unless protocol && sub_process
        record_failure(result, nil, StandardError.new("General/Notification/#{event_name} was not found"), strict:)
        raise TargetCreationError, result if strict

        return result
      end

      targets = tracker_targets(event_name)
      event_names = targets.values.map { |target| target[:event_name] }.uniq
      event_names = [event_name] if event_names.empty?
      protocol_events = sub_process.protocol_events.active.where(name: event_names).index_by(&:name)
      missing_event_names = event_names - protocol_events.keys
      unless missing_event_names.empty?
        record_failure(result, nil,
                       StandardError.new("General/Notification/#{missing_event_names.join(', ')} was not found"),
                       strict:)
        raise TargetCreationError, result if strict

        return result
      end

      targets.each do |master_id, target|
        if skip_existing && tracker_history_exists?(master_id)
          result.skipped += 1
          next
        end

        protocol_event = protocol_events.fetch(target[:event_name])
        result.created += 1 if save_tracker_history(
          master_id, target[:recipients], protocol, sub_process, protocol_event
        )
      rescue StandardError => e
        record_failure(result, master_id, e, strict:)
      end

      raise TargetCreationError, result if strict && result.failed.positive?

      result
    rescue TargetCreationError
      raise
    rescue StandardError => e
      record_failure(result, nil, e, strict:)
      raise TargetCreationError, result if strict

      result
    end

    private

    def tracker_targets(event_name)
      return list_tracker_targets(event_name) if @notification.recipient_hash_from_data

      master_id = real_master_id(@notification.master_id)
      return { master_id => { recipients: recipient_addresses, event_name: } } if master_id

      matched_contacts_by_master(recipient_addresses).transform_values do |recipients|
        { recipients:, event_name: }
      end
    end

    def list_tracker_targets(event_name)
      targets = {}
      @notification.recipient_hash_from_data.each do |recipient|
        list_item = notification_list_item(recipient)
        record_item = notification_record_item(list_item)
        master_id = real_master_id(record_item&.master_id)
        address = recipient[:data].presence || list_item&.data
        target_master_ids = master_id ? [master_id] : matched_contacts_by_master([address]).keys
        target_event_name = list_recipient_event_name(event_name, list_item)

        target_master_ids.each do |target_master_id|
          target = targets[target_master_id] ||= { recipients: [], event_name: target_event_name }
          target[:recipients] << address if address.present? && !target[:recipients].include?(address)
          target[:event_name] = 'Failed' if target_event_name == 'Failed'
        end
      end
      targets
    end

    def matched_contacts_by_master(addresses)
      addresses = Array(addresses).filter_map { |address| address.to_s if address.present? }.uniq
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

    def real_master_id(master_id)
      return unless master_id.present?
      return master_id unless Master::TemporaryMasterIds.include?(master_id.to_i)

      Rails.logger.info "Skipping notification tracker target for temporary master #{master_id}"
      nil
    end

    def notification_list_item(recipient)
      return unless recipient[:list_type].present? && recipient[:id].present?

      @notification.send(:list_item_for, recipient[:list_type], recipient[:id])
    rescue StandardError => e
      Rails.logger.info "Unable to resolve notification list item #{recipient[:list_type]}[#{recipient[:id]}]: " \
                        "#{e.class}: #{e.message}"
      nil
    end

    def notification_record_item(list_item)
      return unless list_item.respond_to?(:record_item)

      list_item.record_item(no_exception: true)
    rescue StandardError => e
      Rails.logger.info "Unable to resolve notification list record item: #{e.class}: #{e.message}"
      nil
    end

    def list_recipient_event_name(event_name, list_item)
      return event_name unless event_name == 'Failed' && list_item
      return 'Sent' if %w[sent success].include?(list_item.send_status)

      'Failed'
    rescue StandardError => e
      Rails.logger.info "Unable to resolve notification list recipient status: #{e.class}: #{e.message}"
      event_name
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
      values = if @notification.sms?
                 @notification.recipient_sms_numbers
               else
                 @notification.recipient_emails
               end

      Array(values).filter_map { |value| value.to_s if value.present? }.uniq
    end

    def save_tracker_history(master_id, recipients, protocol, sub_process, protocol_event)
      if Master::TemporaryMasterIds.include?(master_id.to_i)
        Rails.logger.info "Skipping notification tracker entry for temporary master #{master_id}"
        return
      end

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
      :created
    end

    def tracker_history_exists?(master_id)
      TrackerHistory.exists?(item_type: 'Messaging::MessageNotification', item_id: @notification.id, master_id:)
    end

    def record_failure(result, master_id, error, strict:)
      result.failed += 1
      result.errors << { master_id:, error: }
      return if strict

      target = master_id ? " for master #{master_id}" : ''
      Rails.logger.warn "Unable to create notification tracker entry for #{@notification.id}#{target}: " \
                        "#{error.class}: #{error.message}"
    end

    def tracker_notes(recipients)
      notes = ["type: #{@notification.message_type}"]
      notes << "to: #{recipients.join(', ')}" if recipients.any?
      notes << "subject: #{@notification.subject}" if @notification.subject.present?
      notes.join("\n")
    end
  end
end
