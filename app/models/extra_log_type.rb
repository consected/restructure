# Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
# They provide the ability to present different record types in meaningful forms, for recording keeping or
# driving workflows.


class ExtraLogType < ExtraOptions

  ValidSaveTriggers = [:notify, :create_reference, :update_reference, :create_filestore_container].freeze


  def self.add_key_attributes
    [:references, :label, :save_trigger, :e_sign, :nfs_store]
  end

  attr_accessor(*self.key_attributes)

  def self.attr_defs

    res = {
      label: "button label",
      references: {
        model_name: {
          label: "button label",
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
            edit: 'hide|readonly|not_embedded|select_or_add',
            show: 'hide|readonly|see_presence',
            new: 'outside_this|not_embedded|select_or_add'
          },
          prevent_disable: "true|false (default = false) OR reference",
          allow_disable_if_not_editable: "true|false (default = false) OR reference",
          also_disable_record: "when disabled, also disable the referenced record",
          creatable_if: "conditional rules"
        }
      },
      save_trigger: {
        on_create: {
          notify: SaveTriggers::Notify.config_def(if_extras: "ref: ** conditions reference **"),
          create_reference: SaveTriggers::CreateReference.config_def(if_extras: "ref: ** conditions reference **"),
          update_reference: SaveTriggers::UpdateReference.config_def(if_extras: "ref: ** conditions reference **"),
          create_filestore_container: SaveTriggers::CreateFilestoreContainer.config_def(if_extras: "ref: ** conditions reference **")
        },
        on_update: {
        },
        on_save: {
          notes: 'on_save: provides a shorthand for on_create and on_update. on_create and on_update override on_save configurations.'
        },
        on_disable: {
          notes: 'on_disable: is triggered for any item that has a field named disabled that is switched to true'
        },
        on_upload: {

        }

      },
      e_sign: {
        document_reference: SaveTriggers::CreateReference.config_def(if_extras: "ref: ** conditions reference **"),
        title: 'title to appear at top of prepared document',
        intro: 'text to appear at top of prepared document'
      },
      nfs_store: NfsStore::Config::ExtraOptions.config_def

    }
    res.merge(super)
  end

  def initialize name, config, parent_activity_log
    super(name, config, parent_activity_log)


    raise FphsException.new "extra log options name: property can not be blank" if self.name.blank?
    raise FphsException.new "extra log options caption_before: must be a hash of {field_name: caption, ...}" if self.caption_before && !self.caption_before.is_a?(Hash)

    init_caption_before

    self.label ||= name.to_s.humanize

    clean_references_def
    clean_e_sign_def

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

    self.save_trigger[:on_upload] ||= {}
    self.save_trigger[:on_disable] ||= {}

  end

  def clean_references_def
    if self.references
      new_ref = {}
      if self.references.is_a? Array
        self.references.each do |refitem|
          # Make all keys singular, to simplify configurations
          refitem.each do |k,v|
            if k.to_s != k.to_s.singularize
              new_k = k.to_s.singularize.to_sym
              refitem[new_k] = refitem.delete(k)
            end
          end
          refitem.each do |k,v|
            vi = v[:add_with] && v[:add_with][:extra_log_type]
            ckey = k.to_s
            ckey += "_#{vi}" if vi
            new_ref[ckey.to_sym] = {k => v}
          end
        end
      else
        new_ref = {}
        fix_refs = {}

        # Make all keys singular, to simplify configurations
        # The changes can't be made directly inside the iteration, so handle it in two steps
        self.references.each do |k,v|
          if k.to_s != k.to_s.singularize
            fix_refs[k] = self.references[k]
          end
        end

        fix_refs.each do |k,v|
          new_k = k.to_s.singularize.to_sym
          self.references[new_k] = self.references.delete(k)
        end

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
          to_class = ModelReference.to_record_class_for_type(mn)
          elt = conf[:add_with] && conf[:add_with][:extra_log_type]
          add_with_elt = nil
          if elt && to_class.respond_to?(:human_name_for)
            add_with_elt = to_class.human_name_for(elt)
          end
          refitem[mn][:to_record_label] = conf[:label] || add_with_elt || to_class&.human_name
          refitem[mn][:no_master_association] = to_class.no_master_association if to_class&.respond_to?(:no_master_association)
          refitem[mn][:to_model_name_us] = to_class&.to_s&.ns_underscore
        end
      end

    end

  end

  def clean_e_sign_def
    if self.e_sign
      # Set up the structure so that we can use the standard reference methods to parse the configuration
      self.e_sign[:document_reference] = {item: self.e_sign[:document_reference]} unless self.e_sign[:document_reference][:item]
      self.e_sign[:document_reference].each do |k, refitem|

        # Make all keys singular, to simplify configurations
        refitem.each do |k,v|
          if k.to_s != k.to_s.singularize
            new_k = k.to_s.singularize.to_sym
            refitem[new_k] = refitem.delete(k)
          end
        end

        refitem.each do |mn, conf|
          to_class = ModelReference.to_record_class_for_type(mn)

          refitem[mn][:to_record_label] = conf[:label] || to_class&.human_name
          refitem[mn][:no_master_association] = to_class.no_master_association if to_class&.respond_to?(:no_master_association)
          refitem[mn][:to_model_name_us] = to_class&.to_s&.ns_underscore
        end
      end
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

  def calc_save_trigger_if obj, alt_on: nil
    ca = ConditionalActions.new self.save_trigger, obj

    if alt_on == :upload
      action = :on_upload
    elsif obj._created
      action = :on_create
    elsif obj._disabled
      action = :on_disable
    elsif obj._updated
      action = :on_update
    else
      # Neither create or update - so just return
      return true
    end

    res = ca.calc_save_action_if

    # Get a list of results from the triggers
    results = []

    if res.is_a?(Hash) && res[action]
      res[action].each do |perform, pres|
        # Use the symbol from the list of valid items, to prevent manipulation that could cause Brakeman warnings
        t = ValidSaveTriggers.select {|vt| vt == perform}.first
        if t
          config = self.save_trigger[action][t]
          c = SaveTriggers.const_get(t.to_s.camelize)

          o = c.new config, obj
          # Add the trigger result to the list
          results << o.perform
        else
          raise FphsException.new "The save_trigger action #{action} is not valid when attempting to perform #{perform}"
        end
      end
    end

    # If we had any results then check if they were all true. If they were then return true.
    # Otherwise don't
    if results.length > 0
      return true if results.uniq.length == 1 && results.uniq.first
      return nil
    end

    # No results - return true
    true
  end


  def self.calc_save_triggers obj, configs

    return if configs.nil?
    # Get a list of results from the triggers
    results = []

    configs.each do |perform, pres|
      # Use the symbol from the list of valid items, to prevent manipulation that could cause Brakeman warnings
      t = ValidSaveTriggers.select {|vt| vt == perform}.first
      if t
        config = configs[t]
        c = SaveTriggers.const_get(t.to_s.camelize)

        o = c.new config, obj
        # Add the trigger result to the list
        results << o.perform
      else
        raise FphsException.new "on_complete is not valid when attempting to perform #{perform}"
      end
    end


    # If we had any results then check if they were all true. If they were then return true.
    # Otherwise don't
    if results.length > 0
      return true if results.uniq.length == 1 && results.uniq.first
      return nil
    end

    # No results - return true
    true
  end

  def model_reference_config model_reference
    return unless self.references
    self.references[model_reference.to_record_result_key.to_sym] || self.references[model_reference.to_record.class.table_name.singularize.to_sym]
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
