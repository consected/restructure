# Extra Log Types are additional configurations for forms in addition to the main and general activity log record types.
# They provide the ability to present different record types in meaningful forms, for recording keeping or
# driving workflows.


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
      },
      on_create: {
        create_next_creatable: {
          if: attr_for_conditions
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

    if self.references
      self.references.each do |mn, conf|
        self.references[mn]['to_record_label'] = ModelReference.to_record_class_for_type(mn).human_name
      end
    end
  end


  def self.fields_for_all_in activity_log
    begin
      activity_log.extra_log_type_configs.reject{|e| e.name.in?(['primary', 'blank_log'])}.map(&:fields).reduce([], &:+).uniq
    rescue => e
      raise FphsException.new "Failed to use the extra log options. It is likely that the 'fields:' attribute of one of the extra entries (not primary or blank) is missing or not formatted as expected. #{e}"
    end
  end


  def calc_save_action_if obj
    sa = self.save_action

    if sa.is_a? Hash
      res = {}
      return unless sa.first
      if sa.first.last.is_a? String
        return {sa.first.first => {sa.first.last => true}}
      else
        sa.each do |on_act, conf|
          conf.each do |do_act, conf_act|
            if conf_act['if']
              succ = calc_action_if conf_act['if'].symbolize_keys, obj
            else
              succ = true
            end
            if succ
              res[on_act] ||= {}
              if conf_act['value']
                res[on_act].merge!( do_act => conf_act['value'] )
              else
                res[on_act][do_act] = true
              end
            end
          end
        end
      end
    end
    res
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
