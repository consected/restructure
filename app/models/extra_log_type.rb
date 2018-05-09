# Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
# They provide the ability to present different record types in meaningful forms, for recording keeping or
# driving workflows.

#
# An array of configurations:
#
# step_1:
#   label: Step 1
#   fields:
#     - select_call_direction
#     - select_who
#   caption_before:
#     select_who: Who does this refer to?
#   references:
#     social_security_number
#       from: this | master
#       add: one_to_this | one_to_master | many
#
# step_2:
#   label: Step 2
#   fields:
#     - select_call_direction
#     - extra_text

# Reserved names are: primary, blank
# These correspond to additional options for the primary and blank log fields



class ExtraLogType < ExtraOptions

  def self.add_key_attributes
    [:fields, :references, :label]
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
          filter_by: {
            field_name: 'value to filter the referenced items by'
          },
          view_as: {
            edit: 'readonly',
            show: 'readonly'
          }

        }
      }
    }
    res.merge(super)
  end

  def initialize name, config, parent_activity_log
    super(name, config, parent_activity_log)

    self.fields ||= []

    raise FphsException.new "extra log options name: property can not be blank" if self.name.blank?
    # unless name.in?(['primary', 'blank_log'])
    #   raise FphsException.new "extra log options label: property can not be blank" if self.label.blank?
    #   raise FphsException.new "extra log options fields: property must be an array" unless self.fields.is_a?(Array)
    # end

    raise FphsException.new "extra log options caption_before: must be a hash of {field_name: caption, ...}" if self.caption_before && !self.caption_before.is_a?(Hash)
  end


  def self.fields_for_all_in activity_log
    begin
      activity_log.extra_log_type_configs.reject{|e| e.name.in?(['primary', 'blank_log'])}.map(&:fields).reduce([], &:+).uniq
    rescue => e
      raise FphsException.new "Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the extra entries (not primary or blank) is missing or not formatted as expected. #{e}"
    end
  end


  protected

    def self.options_text activity_log
      activity_log.extra_log_types
    end

    def self.set_defaults activity_log, all_options={}
      # Add primary and blank items if they don't exist
      all_options['primary'] ||= {}
      all_options['blank_log'] ||= {}

      all_options['primary']['label'] ||= activity_log.main_log_name
      all_options['blank_log']['label'] ||= activity_log.blank_log_name
      all_options['primary']['fields'] ||= activity_log.view_attribute_list
      all_options['blank_log']['fields'] ||= activity_log.view_blank_log_attribute_list
    end

end
