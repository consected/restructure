# Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
# They provide the ability to present different record types in meaningful forms, for recording keeping or
# driving workflows.


class ExtraLogType < ExtraOptions

  ValidSaveTriggers = [:notify, :create_reference].freeze


  def self.add_key_attributes
    [:fields, :references, :label, :save_trigger]
  end

  attr_accessor(*self.key_attributes)

  def self.attr_defs

    res = {
      label: "button label",
      fields: [
        'field_name_1', 'field_name_2'
      ],
      references: {
        model_name: {
          from: "this | master",
          add: "many | one_to_master | one_to_this",
          add_with: {
            extra_log_type: "type name",
            item_name: {
              embedded_item: {
                field_name: "value"
              }
            }
          },
          filter_by: {
            field_name: 'value to filter the referenced items by'
          },
          view_as: {
            edit: 'readonly',
            show: 'readonly'
          }
        }
      },
      save_trigger: {
        on_create: {
          notify: SaveTriggers::Notify.config_def(if_extras: attr_for_conditions),
          create_reference: SaveTriggers::CreateReference.config_def(if_extras: attr_for_conditions)
        },
        on_update: {
        },
        on_save: {
          notes: 'on_save: provides a shorthand for on_create and on_update. on_create and on_update override on_save configurations.'
        }

      }

    }
    res.merge(super)
  end

  def initialize name, config, parent_activity_log
    super(name, config, parent_activity_log)

    self.fields ||= []

    raise FphsException.new "extra log options name: property can not be blank" if self.name.blank?
    raise FphsException.new "extra log options caption_before: must be a hash of {field_name: caption, ...}" if self.caption_before && !self.caption_before.is_a?(Hash)

    init_caption_before

    if self.references
      new_ref = {}
      if self.references.is_a? Array
        self.references.each do |refitem|
          refitem.each do |k,v|
            vi = v[:add_with] && v[:add_with][:extra_log_type]
            ckey = k.to_s
            ckey += "_#{vi}" if vi
            new_ref[ckey.to_sym] = {k => v}
          end
        end
      else
        new_ref = {}
        self.references.each do |k, v|
          vi = v[:add_with] && v[:add_with][:extra_log_type]
          ckey = k.to_s
          ckey += "_#{vi}" if vi
          new_ref[ckey.to_sym] = {k => v}
        end
      end

      self.references = new_ref

      self.references.each do |k, refitem|
        refitem.each do |mn, conf|
          refitem[mn][:to_record_label] = ModelReference.to_record_class_for_type(mn).human_name
        end
      end

    end

    self.save_trigger ||= {}
    self.save_trigger = self.save_trigger.symbolize_keys
    # Make save_trigger.on_save the default for on_create and on_update
    os = self.save_trigger[:on_save]
    if os
      ou = self.save_trigger[:on_update] || {}
      oc = self.save_trigger[:on_create] || {}
      self.save_trigger[:on_update] = os.merge(ou)
      self.save_trigger[:on_create] = os.merge(oc)
    end

  end


  def self.fields_for_all_in activity_log
    begin
      activity_log.extra_log_type_configs.reject{|e| e.name.in?([:primary, :blank_log])}.map(&:fields).reduce([], &:+).uniq
    rescue => e
      raise FphsException.new "Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the extra entries (not primary or blank) is missing or not formatted as expected. #{e}"
    end
  end


  def calc_save_action_if obj
    ca = ConditionalActions.new self.save_action, obj
    ca.calc_save_action_if
  end

  def calc_save_trigger_if obj
    ca = ConditionalActions.new self.save_trigger, obj

    if obj._created
      action = :on_create
    elsif obj._updated
      action = :on_update
    else
      # Neither create or update - so just return
      return true
    end

    res = ca.calc_save_action_if

    if res.is_a?(Hash) && res[action]
      res[action].each do |perform, pres|
        # Use the symbol from the list of valid items, to prevent manipulation that could cause Brakeman warnings
        t = ValidSaveTriggers.select {|t| t == perform}.first
        if t
          config = self.save_trigger[action][t]
          c = SaveTriggers.const_get(t.to_s.camelize)

          o = c.new config, obj
          return o.perform
        else
          raise FphsException.new "The save_trigger action #{action} is not valid when attempting to perform #{perform}"
        end
      end
    end

    true
  end

  protected

    def self.options_text activity_log
      activity_log.extra_log_types
    end

    def self.set_defaults activity_log, all_options={}
      # Add primary and blank items if they don't exist
      all_options[:primary] ||= {}
      all_options[:blank_log] ||= {}

      all_options[:primary][:label] ||= activity_log.main_log_name
      all_options[:blank_log][:label] ||= activity_log.blank_log_name
      all_options[:primary][:fields] ||= activity_log.view_attribute_list
      all_options[:blank_log][:fields] ||= activity_log.view_blank_log_attribute_list
    end

    def init_caption_before

      curr_name = @config_obj.name

      item_type = 'item'
      item_type = @config_obj.implementation_class.parent_type if @config_obj.implementation_class.respond_to? :parent_type

      cb = {
        protocol_id: {
          caption: "Select the protocol this #{curr_name} is related to. A tracker event will be recorded under this protocol."
        },
        "set_related_#{item_type}_rank".to_sym => {
          caption: "To change the rank of the related #{item_type.to_s.humanize}, select it:"
        }
      }

      cb[:all_fields] = {
        caption: "Enter details about the #{curr_name}"
        } if @caption_before[:all_fields].blank? && @fields.include?('select_call_direction')


      cb[:submit] =  {
        caption: 'To add specific protocol status and method records, save this form first.'
        } if @fields.include?('protocol_id') && !@fields.include?('sub_process_id' )

      @caption_before.merge! cb

    end


end
