# frozen_string_literal: true

module OptionConfigs
  # Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
  # They provide the ability to present different record types in meaningful forms, for recording keeping or
  # driving workflows.
  class ActivityLogOptions < ExtraOptions
    ValidNfsStoreKeys = %i[always_use_this_for_access_control container_files pipeline user_file_actions view_options
                           can].freeze
    ValidNfsStoreCanPerformKeys = %i[download_if view_files_as_image_if view_files_as_html_if send_files_to_trash_if
                                     move_files_if user_file_actions_if].freeze

    def self.add_key_attributes
      %i[e_sign nfs_store]
    end

    attr_accessor(*key_attributes)

    def initialize(name, config, parent_activity_log)
      super(name, config, parent_activity_log)

      if @config_obj.disabled
        Rails.logger.info "configuration for this activity log has not been enabled: #{@config_obj.table_name}"
        return
      end
      raise FphsException, 'extra log options name: property can not be blank' if self.name.blank?

      # Activity logs have some predefined captions. Set these up.
      if caption_before && !caption_before.is_a?(Hash)
        raise FphsException, 'extra log options caption_before: must be a hash of {field_name: caption, ...}'
      end

      init_caption_before

      clean_e_sign_def
      clean_nfs_store_def
    end

    def clean_nfs_store_def
      return unless nfs_store

      can_perform = nfs_store[:can]

      unless valid_config_keys?(nfs_store, ValidNfsStoreKeys)
        failed_config :nfs_store,
                      "nfs_store contains invalid keys #{nfs_store.keys} - " \
                      "expected only #{ValidNfsStoreKeys}"
      end

      unless can_perform.nil? || valid_config_keys?(can_perform, ValidNfsStoreCanPerformKeys)
        failed_config :nfs_store__can,
                      "nfs_store.can contains invalid keys #{can_perform.keys} - " \
                      "expected only #{ValidNfsStoreCanPerformKeys}"
      end

      NfsStore::Config::ExtraOptions.clean_def nfs_store
    end

    def clean_e_sign_def
      return unless e_sign

      # Set up the structure so that we can use the standard reference methods to parse the configuration
      e_sign[:document_reference] = { item: e_sign[:document_reference] } unless e_sign[:document_reference][:item]
      e_sign[:document_reference].each_value do |refitem|
        # Make all keys singular, to simplify configurations
        refitem.transform_keys! do |k|
          new_k = k.to_s.singularize.to_sym
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

    # A list of all fields defined within all the individual activity definitions. This does not include
    # the field lists for the old-style primary and blank logs.
    def self.fields_for_all_in(al_def)
      al_def.option_configs.reject { |e| e.name.in?(%i[primary blank_log]) }.map(&:fields).reduce([], &:+).uniq
    rescue StandardError => e
      raise FphsException, <<~END_TEXT
        Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the activities
        (not primary or blank) is missing or not formatted as expected, or a @library inclusion has an error.
        #{e}
      END_TEXT
    end

    # Check if any of the configs were bad
    # This should be extended to provide additional checks when options are saved
    def self.raise_bad_configs(option_configs)
      super
    end

    def calc_save_action_if(obj)
      ca = ConditionalActions.new save_action, obj
      ca.calc_save_option_if check_action_if: true
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
