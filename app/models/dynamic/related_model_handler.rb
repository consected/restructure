# frozen_string_literal: true

module Dynamic
  module RelatedModelHandler
    extend ActiveSupport::Concern
    include GeneralDataConcerns

    included do
      before_save :sync_item_data
      before_save :set_related_fields
      before_save :set_allow_tracker_sync

      after_save :sync_set_related_fields

      attr_accessor :action_name

      # a list of embedded items (full data for each model reference)
      # is available, if the #populate_embedded_items method is called
      # otherwise it is nil
      attr_accessor :embedded_items
    end

    # Sync the tracker by adding a record to the protocol if it is set
    # This should only happen one time, since in the case of edit / update, a duplicate
    # item could be created otherwise.
    def sync_tracker
      return unless respond_to?(:protocol_id) && protocol_id

      return unless @allow_tracker_sync

      protocol = Classification::Protocol.find(protocol_id)

      # if we are not already passing through sub_process based on a user selection then
      # look up what the Activity name is for protocol sub processes
      if attribute_names.include? 'sub_process_id'
        sub_process_id = self.sub_process_id
        sub_process = Classification::SubProcess.find(sub_process_id)
      else
        # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
        sub_process = protocol.sub_processes.where(name: ActivityLog.sub_process_name).first
        sub_process_id = sub_process.id
      end
      # if we are not already passing through protocol_event based on a user selection then
      # then use the protocol event name matching the admin activity log definition for this model
      if attribute_names.include? 'protocol_event_id'
        protocol_event_id = self.protocol_event_id
      elsif sub_process
        unless self.class.activity_log_name
          raise "activity_log_name not set for #{self.class}. Can't get the protocol event without it"
        end

        # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
        pe = sub_process.protocol_events.where(name: self.class.activity_log_name).first
        if pe
          protocol_event_id = pe.id
        else
          raise "Could not find a protocol event for sub process #{sub_process_id} in sync_tracker (#{self.class}). There are these: #{sub_process.protocol_events.map(&:name).join(', ')}."
        end
      end

      # be sure about the user being set, to avoid hidden errors
      raise 'no user set when syncing tracker' unless master.current_user

      t = master.trackers.create(protocol_id: protocol_id,
                                 sub_process_id: sub_process_id,
                                 protocol_event_id: protocol_event_id,
                                 item_id: id,
                                 item_type: self.class.name,
                                 event_date: action_when,
                                 notes: data)

      # check and raise error that is usable by a user if there was a problem (for example, a required field not set)
      raise FphsException, "could not create tracker record: #{t.errors.full_messages.join('; ')}" unless t&.valid?

      t
    end

    def fields_to_sync
      self.class.fields_to_sync
    end

    def format_sync_fields
      return unless parent_class

      fields_to_sync.each do |f|
        formatter = "format_#{f}"
        next unless parent_class.respond_to? formatter

        self[f] = if respond_to? :rec_type
                    parent_class.send("format_#{f}", self[f], rec_type)
                  else
                    parent_class.send("format_#{f}", self[f])
                  end
      end
    end

    # sync the attributes that are common between the parent item and the new logged item,
    # to ensure that there is a true record of the original data (in case something is changed
    # in the parent item subsequently)
    # Skip this if the item is not set (for a blank activity log)
    def sync_item_data
      return true unless item

      fields_to_sync.each do |f|
        send("#{f}=", item.send(f))
      end
    end

    def set_related_fields
      @set_related_fields ||= setup_set_related_fields
    end

    # handle fields that start with set_related_
    # these fields allow a field in a related model to be updated
    # for example, this allows a rank in a phone number to be set when displaying
    # a form for a phone activity log
    # the full field name in this case would be set_related_player_contact_rank
    def setup_set_related_fields
      srfs = {}

      attribute_names.each do |field_name|
        next unless field_name.to_s.start_with?('set_related_')

        # get the model name of the related model and its field by
        # getting rid of the set_related_prefix_ then looking for associated model
        # to find one with a matching name
        relitem_field = ''
        relitem_name = ''
        relitem_name_and_field = field_name.to_s.gsub('set_related_', '')
        relitem_list = self.class.reflect_on_all_associations(:belongs_to).map(&:name)

        relitem_list.each do |r|
          next unless relitem_name_and_field.start_with?(r.to_s)

          relitem_field = relitem_name_and_field.gsub("#{r}_", '')
          relitem_name = r.to_s
          # remake the model_field name with the pluralized model name, since this is
          # how the field is referred to in normal field naming and general selections
          relitem_name_and_field = "#{relitem_name.pluralize}_#{relitem_field}"
          break
        end

        if relitem_name.blank?
          raise FphsException, "The field #{field_name} does not correspond to one of #{relitem_list}"
        end

        # get the underlying related item and the value of the field
        relitem = send(relitem_name)

        # handle the situation where a blank item is not using the related items
        next unless relitem

        relitem_field_val = relitem.send(relitem_field)

        curr_val = send(field_name)
        # don't set the value if it is already set, since this indicates we have
        # already configured the model
        send("#{field_name}=", relitem_field_val) unless curr_val

        srfs[field_name.to_sym] = {
          item: relitem,
          name_and_field: relitem_name_and_field.to_sym,
          field: relitem_field.to_sym,
          value: relitem_field_val
        }
      end
      srfs
    end

    # set the fields that are marked as set_related in the current model, back
    # into the related model
    def sync_set_related_fields
      return true unless set_related_fields

      set_related_fields.each do |k, s|
        new_val = send(k)

        curr_val = s[:item].send(s[:field])

        next unless !new_val.blank? && curr_val != new_val

        s[:item].send("#{s[:field]}=", new_val)
        # Do not set master - this should already be set, and setting it again breaks
        # secondary_key matched saves
        s[:item].master = master unless s[:item].master
        s[:item].master.current_user = master_user || user unless s[:item].master_user
        res = s[:item].save
        raise "Failed to save related item. #{s[:item].errors.full_messages.join('; ')}" unless res
      end
      true
    end

    # Store the result of allowing a tracker sync to happen before save, when we
    # would lose access to the required change information.
    def set_allow_tracker_sync
      @allow_tracker_sync = true if !persisted? || (respond_to?(:protocol_id) && protocol_id_changed?)
    end
  end
end
