# frozen_string_literal: true

module OptionConfigs
  # Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
  # They provide the ability to present different record types in meaningful forms, for recording keeping or
  # driving workflows.
  class ActivityLogOptions < ExtraOptions
    def self.add_key_attributes
      %i[references e_sign nfs_store]
    end

    attr_accessor(*key_attributes, :bad_ref_items)

    def initialize(name, config, parent_activity_log)
      super(name, config, parent_activity_log)

      if @config_obj.disabled
        Rails.logger.info "configuration for this activity log has not been enabled: #{@config_obj.table_name}"
        return
      end
      raise FphsException, 'extra log options name: property can not be blank' if self.name.blank?
      if caption_before && !caption_before.is_a?(Hash)
        raise FphsException, 'extra log options caption_before: must be a hash of {field_name: caption, ...}'
      end

      init_caption_before

      clean_references_def
      clean_e_sign_def
      clean_nfs_store_def
    end

    def clean_nfs_store_def
      NfsStore::Config::ExtraOptions.clean_def nfs_store if nfs_store
    end

    def clean_references_def
      if references
        new_ref = {}
        if references.is_a? Array
          references.each do |refitem|
            # Make all keys singular, to simplify configurations
            add_refitem = {}
            refitem.each do |k, _v|
              if k.to_s != k.to_s.singularize
                new_k = k.to_s.singularize.to_sym
                add_refitem[new_k] = refitem.delete(k)
              end
            end

            refitem.merge! add_refitem

            refitem.each do |k, v|
              vi = v[:add_with] && v[:add_with][:extra_log_type]
              ckey = k.to_s
              ckey += "_#{vi}" if vi
              new_ref[ckey.to_sym] = { k => v }
            end
          end
        else
          new_ref = {}
          fix_refs = {}

          # Make all keys singular, to simplify configurations
          # The changes can't be made directly inside the iteration, so handle it in two steps
          references.each do |k, _v|
            fix_refs[k] = references[k] if k.to_s != k.to_s.singularize
          end

          fix_refs.each do |k, _v|
            new_k = k.to_s.singularize.to_sym
            references[new_k] = references.delete(k)
          end

          references.each do |k, v|
            vi = v[:add_with] && v[:add_with][:extra_log_type]
            ckey = k.to_s
            ckey += "_#{vi}" if vi
            new_ref[ckey.to_sym] = { k => v }
          end
        end

        self.references = new_ref

        references.each do |_k, refitem|
          self.bad_ref_items = []
          refitem.each do |mn, conf|
            to_class = ModelReference.to_record_class_for_type(mn)

            if to_class
              elt = conf[:add_with] && conf[:add_with][:extra_log_type]
              add_with_elt = nil
              add_with_elt = to_class.human_name_for(elt) if elt && to_class.respond_to?(:human_name_for)
              refitem[mn][:to_record_label] = conf[:label] || add_with_elt || to_class.human_name

              if to_class.respond_to?(:no_master_association)
                refitem[mn][:no_master_association] = to_class.no_master_association
              end

              refitem[mn][:to_model_name_us] = to_class.to_s&.ns_underscore
              refitem[mn][:to_model_class_name] = to_class.to_s
              refitem[mn][:to_table_name] = to_class.table_name
              tsn = nil

              if to_class.respond_to?(:definition)
                cd = to_class.definition
                tsn = cd.schema_name
                tct = cd.class.to_s
                refitem[mn][:to_schema_name] = tsn
                refitem[mn][:to_class_type] = tct
              end
            else
              bad_ref_items << mn
              Rails.logger.warn "extra log type reference for #{mn} does not exist as a class in #{name} / #{config_obj.name}"
              Rails.logger.info 'Will clean up reference to avoid it being used again in this session'
            end
          end

          # Cleanup bad items
          bad_ref_items.each do |br|
            refitem.delete(br)
          end
        end

      end
    end

    def clean_e_sign_def
      if e_sign
        # Set up the structure so that we can use the standard reference methods to parse the configuration
        e_sign[:document_reference] = { item: e_sign[:document_reference] } unless e_sign[:document_reference][:item]
        e_sign[:document_reference].each do |_k, refitem|
          # Make all keys singular, to simplify configurations
          refitem.each do |k, _v|
            if k.to_s != k.to_s.singularize
              new_k = k.to_s.singularize.to_sym
              refitem[new_k] = refitem.delete(k)
            end
          end

          refitem.each do |mn, conf|
            to_class = ModelReference.to_record_class_for_type(mn)

            refitem[mn][:to_record_label] = conf[:label] || to_class&.human_name
            if to_class&.respond_to?(:no_master_association)
              refitem[mn][:no_master_association] = to_class.no_master_association
            end
            refitem[mn][:to_model_name_us] = to_class&.to_s&.ns_underscore
          end
        end
      end
    end

    # A list of all fields defined within all the individual activity definitions. This does not include
    # the field lists for the old-style primary and blank logs.
    def self.fields_for_all_in(al_def)
      al_def.option_configs.reject { |e| e.name.in?(%i[primary blank_log]) }.map(&:fields).reduce([], &:+).uniq
    rescue StandardError => e
      raise FphsException, <<~END_TEXT
        Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the activities
        (not primary or blank) is missing or not formatted as expected, or a @library inclusion has an error. #{e}
      END_TEXT
    end

    # Get a complete set of all tables to be accessed by model reference configurations,
    # with a value representing what they are associated from.
    def self.referenced_tables_for_all_in(al_def)
      res = []

      al_def.option_configs.map(&:references).compact.each do |act_refs|
        act_refs.each do |ref_name, outer_config|
          outer_config.each do |full_name, ref_config|
            details = ref_config.slice(:to_table_name, :to_schema_name, :to_model_class_name, :to_class_type,
                                       :from, :without_reference, :no_master_association)
            details.merge! reference_name: ref_name, full_ref_name: full_name
            res << details
          end
        end
      end

      res
    rescue StandardError => e
      raise FphsException, <<~END_TEXT
        Failed to use the extra log options. It is likely that the 'references:' attribute of one of
        activities is not formatted as expected, or a @library inclusion has an error. #{e}
      END_TEXT
    end

    # Check if any of the configs were bad
    # This should be extended to provide additional checks when options are saved
    # @todo - work out why the "raise" was disabled and whether it needs changing
    def self.raise_bad_configs(option_configs)
      bad_configs = option_configs.select { |c| c.bad_ref_items.present? }
      # raise FphsException, "Bad reference items: #{bad_configs.map(&:bad_ref_items)}" if bad_configs.present?
    end

    def calc_save_action_if(obj)
      ca = ConditionalActions.new save_action, obj
      ca.calc_save_option_if check_action_if: true
    end

    #
    # Get the model reference configuration hash, based on the to_record.
    # For flexibility, this may be keyed with a singular or plural key that is one of:
    # the full activity log with extra log type (for example activity_log__player_contact_step_1)
    # the database table name (for example activity_log_player_contacts)
    # the model resource name (for example activity_log__player_contact)
    def model_reference_config(model_reference)
      return unless references

      references[model_reference.to_record_result_key.to_sym] ||
        references[model_reference.to_record.class.table_name.singularize.to_sym] ||
        references[model_reference.to_record.class.name.ns_underscore.singularize.to_sym]
    end

    class << self
      protected

      def set_defaults(activity_log, all_options = {})
        # Add primary and blank items if they don't exist
        all_options[:primary] ||= {}
        all_options[:blank_log] ||= {}

        all_options[:primary][:label] ||= activity_log.main_log_name
        all_options[:blank_log][:label] ||= activity_log.blank_log_name
        all_options[:primary][:fields] ||= activity_log.view_attribute_list
        all_options[:blank_log][:fields] ||= activity_log.view_blank_log_attribute_list
      end
    end

    protected

    def init_caption_before
      curr_name = @config_obj.name

      item_type = 'item'
      item_type = @config_obj.item_type.to_sym if @config_obj.item_type

      cb = {
        protocol_id: {
          caption: "Select the protocol this #{curr_name} is related to. A tracker event will be recorded under this protocol."
        },
        "set_related_#{item_type}_rank".to_sym => {
          caption: "To change the rank of the related #{item_type.to_s.humanize}, select it:"
        }
      }

      if @caption_before[:all_fields].blank? && @fields.include?('select_call_direction')
        cb[:all_fields] = {
          caption: "Enter details about the #{curr_name}"
        }
      end

      if @fields.include?('protocol_id') && !@fields.include?('sub_process_id')
        cb[:submit] = {
          caption: 'To add specific protocol status and method records, save this form first.'
        }
      end

      @caption_before.merge! cb
    end
  end
end
