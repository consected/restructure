# frozen_string_literal: true

class SaveTriggers::CreateReference < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each do |model_name, config|
        vals = {}
        force_create = config[:force_create]
        to_existing_record = config[:to_existing_record]
        create_in = config[:in]
        create_if = config[:if]
        create_with = config[:with]

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if create_if
          ca = ConditionalActions.new create_if, @item
          next unless ca.calc_action_if
        end

        create_with&.each do |fn, def_val|
          res = FieldDefaults.calculate_default @item, def_val
          vals[fn] = res
        end

        @item.transaction do
          new_type = @master.assoc_named(model_name.to_s.pluralize)
          if to_existing_record
            to_record_id = to_existing_record[:record_id]
            raise FphsException, 'record_id must be set in to_existing_record' unless to_record_id

            ca = ConditionalActions.new to_record_id, @item
            to_existing_record_id = ca.get_this_val
            new_item = new_type.find(to_existing_record_id)
          else
            new_item = new_type.new vals
            new_item.force_save! if force_create
            new_item.save!
          end

          case create_in
          when 'this'
            ModelReference.create_with @item, new_item, force_create: force_create
          when 'referring_record'
            ModelReference.create_with @item.referring_record, new_item, force_create: force_create
          when 'master'
            # 'master' indicates that we want to create an instance belonging to the master without
            # creating a ModelReference. Do nothing here.
          when 'master_with_reference'
            ModelReference.create_from_master_with @master, new_item, force_create: force_create
          else
            raise FphsException, "Unknown 'in' value in create_reference"
          end
        end
      end
    end
  end
end
