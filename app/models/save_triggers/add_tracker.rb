# frozen_string_literal: true

# Trigger to handle adding a tracker entry.
# The entry is made to a the named protocol, sub process and optionally protocol event name
# Optionally an item (model instance) may be referenced, to provide the tracker "paperclip"
# reference back to a different item. By default the current item is used.
# Also, if necessary, an alternative master_id may be specified.
class SaveTriggers::AddTracker < SaveTriggers::SaveTriggersBase
  #
  # The calculated / substituted configs values within the with: Hash
  attr_accessor :config_values
  # All results as array of Hash {<protocol_name>: Tracker}
  attr_accessor :trackers
  # Protocol name from the key on each configuration item
  attr_accessor :protocol_name

  def initialize(config, item)
    super

    self.trackers = []
  end

  #
  # Run the trigger definition against the current item
  # @return [Array{Hash{protocol_name: Classification::Tracker}}] <description>
  def perform
    model_defs.each do |model_def|
      model_def.each do |pn, c|
        self.this_config = c
        self.protocol_name = pn
        unless if_evaluates(this_config[:if])
          trackers << { protocol_name => nil }
          next
        end

        setup_with_config
        # be sure about the user being set, to avoid hidden errors
        raise 'no user set when adding tracker' unless use_master.current_user

        t = use_master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          protocol_event_id: protocol_event&.id,
          notes: config_values[:notes],
          item: use_item,
          event_date: event_date
        )

        trackers << { protocol_name => t }
      end
    end
    trackers
  end

  private

  #
  # Each of the attributes within the with: Hash may be a literal value,
  # include {{substitutions}} or may be a hash representing a conditional action
  # that returns a value with return_value
  def setup_with_config
    @protocol = nil
    @sub_process = nil
    @protocol_event = nil
    @use_item = nil
    @use_master = nil

    self.config_values = {}

    this_config[:with].each do |fn, def_val|
      if def_val.is_a? Hash
        ca = ConditionalActions.new def_val, @item
        res = ca.get_this_val
      else
        res = FieldDefaults.calculate_default @item, def_val
      end

      config_values[fn] = res
    end
    config_values.symbolize_keys
  end

  #
  # Add trigger to the master, specified by:
  # - the master record specified by {with: master_id:}
  # - the master for the specified item_type / item_id
  # - the current master by default
  # @return [Master]
  def use_master
    return @use_master if @use_master

    master_id = config_values[:master_id]
    @use_master = if master_id
                    Master.find(master_id)
                  else
                    use_item&.master || @master
                  end

    unless @use_master.current_user
      cu = @item.current_user if @item.respond_to? :current_user
      cu = @master.current_user if cu.nil? && @master
      @use_master.current_user = cu
    end

    @use_master
  end

  #
  # Use the current item (activity log, dynamic model) by default,
  # or the record specified by item_id: & item_type:
  # item_type: may be a class.name format, or namespaced resource_name
  # @return [UserBase]
  def use_item
    return @use_item if @use_item

    item_id = config_values[:item_id]
    item_type = config_values[:item_type]

    return @use_item = item unless item_id && item_type

    item_type = item_type.ns_camelize
    item_class = Admin::AdminBase.class_from_name(item_type)
    @use_item = item_class.find(item_id)
  end

  #
  # Lookup protocol by name from config
  # If a with: configuration has been specified using protocol_name:
  # or protocol_id:
  # use this, instead of the trigger definition key
  # @return [Classification::Protocol]
  def protocol
    if config_values.key? :protocol_id
      pid = config_values[:protocol_id]
      @protocol ||= Classification::Protocol.where(id: pid).first
    elsif config_values.key? :protocol_name
      pn = config_values[:protocol_name]
      @protocol ||= Classification::Protocol.where(name: pn).first
    else
      @protocol ||= Classification::Protocol.where(name: protocol_name).first
    end
    raise "Could not find protocol name in add_tracker event (#{pn})" unless @protocol

    @protocol
  end

  #
  # Lookup sub process by name from config
  # @return [Classifications::SubProcess]
  def sub_process
    spn = config_values[:sub_process_name]
    raise 'sub_process_name not specified in add_tracker_event' if spn.blank?

    # Note that we do not use the enabled scope, since we allow this item
    # to be disabled (preventing its use by users)
    @sub_process ||= protocol.sub_processes.where(name: spn).first
    unless @sub_process
      raise "Could not find a sub process name (#{spn}) for protocol #{protocol.id} in " \
            "add_tracker event. There are these: #{protocol.sub_processes.map(&:name).join(', ')}."
    end

    @sub_process
  end

  #
  # Lookup protocol event, if a protocol_event_name has been specified in the config
  # @return [Classifications::ProtocolEvent]
  def protocol_event
    pen = config_values[:protocol_event_name]
    return if pen.blank?

    # Note that we do not use the enabled scope, since we allow this item
    # to be disabled (preventing its use by users)
    @protocol_event ||= sub_process.protocol_events.where(name: pen).first
    unless @protocol_event
      raise "Could not find a protocol event (#{pen}) for sub process #{sub_process.id} in " \
            "add_tracker event. There are these: #{sub_process.protocol_events.map(&:name).join(', ')}."
    end

    @protocol_event
  end

  #
  # Event date can be defined in the configuration. By default it is now
  # @return [Date]
  def event_date
    d = config_values[:event_date]
    d = FieldDefaults.calculate_default @item, d, :date if d
    d || DateTime.now
  end
end
