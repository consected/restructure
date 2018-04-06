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



class ExtraLogType

  attr_accessor :name, :label, :fields, :references, :resource_name, :caption_before

  def initialize name, config, parent_activity_log
    @name = name

    config.each {|k, v| self.send("#{k}=", v)}

    self.fields ||= []

    pal = parent_activity_log

    self.resource_name = "#{pal.full_implementation_class_name.ns_underscore}__#{self.name.underscore}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys

    raise FphsException.new "extra log options name: property can not be blank" if self.name.blank?
    unless name.in?(['primary', 'blank'])
      raise FphsException.new "extra log options label: property can not be blank" if self.label.blank?
      raise FphsException.new "extra log options fields: property must be an array" unless self.fields.is_a?(Array)
    end

    raise FphsException.new "extra log options caption_before: must be a hash of {field_name: caption, ...}" if self.caption_before && !self.caption_before.is_a?(Hash)
  end

  def self.parse_config activity_log

    c = activity_log.extra_log_types

    configs = []
    begin
      if c.present?
        res = YAML.load(c)
      else
        res = {}
      end

      # Add primary and blank items if they don't exist
      res['primary'] ||= {}
      res['blank'] ||= {}

      res.each do |k, v|
        i = ExtraLogType.new k, v, activity_log
        configs << i
      end
    # rescue

    end

    return configs
  end


  def self.fields_for_all_in activity_log
    begin
      activity_log.extra_log_type_configs.reject{|e| e.name.in?(['primary', 'blank'])}.map(&:fields).reduce([], &:+).uniq
    rescue => e
      raise FphsException.new "Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the extra entries (not primary or blank) is missing or not formatted as expected. #{e}"
    end
  end

end
