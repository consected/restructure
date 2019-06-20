class SaveTriggers::AddTracker < SaveTriggers::SaveTriggersBase

  def self.config_def if_extras: {}
    [
      {
        protocol_name: {
          if: if_extras,
          with: {
            master_id: "alternative master_id based on value or reference definition",
            sub_process: "name",
            protocol_event: "name",
            item_type: 'model name',
            item_id: 'model id'
          }
        }
      }
    ]
  end

  def initialize config, item
    super

    @model_defs = config

  end

  def perform

    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each do |protocol_name, config|

        vals = {}

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ExtraLogType#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        config[:with].each do |fn, def_val|

          if def_val.is_a? Hash
            ca = ConditionalActions.new def_val, @item
            res = ca.get_this_val
          else
            res = FieldDefaults.calculate_default @item, def_val
          end

          vals[fn] = res
        end

        vals.stringify_keys!

        @item.transaction do

          if vals[:master_id]
            master = Master.find(vals[:master_id])
          else
            master = @master
          end

          master.current_user ||= current_user

          protocol = Classification::Protocol.where(name: vals[:protocol_name]).first

          # look up what the name for the sub process
          # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
          sub_process = protocol.sub_processes.where(name: vals[:sub_process_name]).first
          sub_process_id = sub_process.id


          # lookup protocol event
          if sub_process
            # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
            pe = sub_process.protocol_events.where(name: vals[:protocol_event_name]).first
            if pe
              protocol_event_id = pe.id
            else
              raise "Could not find a protocol event for sub process #{sub_process_id} in add_tracker event. There are these: #{sub_process.protocol_events.map(&:name).join(', ')}."
            end
          end

          # be sure about the user being set, to avoid hidden errors
          raise "no user set when adding tracker" unless master.current_user

          t = master.trackers.create(protocol_id: protocol_id, sub_process_id: sub_process_id, protocol_event_id: protocol_event_id,
                        item_id: self.id, item_type: self.class.name, event_date: DateTime.now)

        end

      end

    end

  end

end
