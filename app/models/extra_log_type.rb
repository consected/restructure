# Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
# They provide the ability to present different record types in meaningful forms, for recording keeping or
# driving workflows.
class ExtraLogType

  attr_accessor :name, :label, :fields, :users

  def initialize name, config
    @name = name

    config.each {|k, v| self.send("#{k}=", v)}
  end

  def self.parse_config activity_log

    c = activity_log.extra_log_types

    configs = []
    if c.present?
      begin
        res = YAML.load(c)
        res.each do |k, v|
          i = ExtraLogType.new k, v
          configs << i
        end
      # rescue

      end
    end

    return configs
  end


  def self.fields_for_all_in activity_log
    activity_log.extra_log_type_configs.map(&:fields).reduce([], &:+).uniq << 'extra_log_type'
  end

end
