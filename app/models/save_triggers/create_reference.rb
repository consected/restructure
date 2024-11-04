# frozen_string_literal: true

class SaveTriggers::CreateReference < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @item.save_trigger_results['created_references'] ||= []
    @item.save_trigger_results['created_items'] ||= []
    @item.save_trigger_results['created_results'] ||= []

    @model_defs.each do |model_def|
      model_def.each do |model_name, config|
        vals = {}
        force_create = config[:force_create]
        force_not_valid = true if config[:force_not_valid]
        to_existing_record = config[:to_existing_record]
        create_in = config[:in]
        create_if = config[:if]
        create_with = config[:with]
        with_result = config[:with_result]

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if create_if
          ca = ConditionalActions.new create_if, @item
          unless ca.calc_action_if
            @item.save_trigger_results['created_results'] << false
            next
          end
        end

        self.in_master = @master

        handle_with_result with_result, vals
        handle_with_attributes create_with, vals

        @item.transaction do
          new_type = in_master.assoc_named(model_name.to_s.pluralize)
          if to_existing_record
            to_record_id = to_existing_record[:record_id]
            raise FphsException, 'record_id must be set in to_existing_record' unless to_record_id

            to_existing_record_id = FieldDefaults.calculate_default @item, to_record_id
            new_item = new_type.find(to_existing_record_id)
          else
            vals[:ignore_configurable_valid_if] = force_not_valid
            new_item = new_type.new vals
            # new_item.ignore_configurable_valid_if = force_not_valid
            if force_create
              new_item.send(:force_write_user)
              new_item.force_save!
            end
            if vals[:embedded_item]
              # Ensure the embedded item has its attributes set before the
              # new item starts to save, to avoid any issues. Save triggers
              # within the new item may reference the embedded item, and will
              # need the real information in place early in the process.
              new_item.prep_embedded_item(vals[:embedded_item],
                                          force_create:,
                                          force_not_valid:)
            end
            new_item.save!

          end

          res =
            case create_in
            when 'this'
              ModelReference.create_with @item, new_item, force_create:
            when 'referring_record'
              ModelReference.create_with @item.referring_record, new_item, force_create:
            when 'master'
              # 'master' indicates that we want to create an instance belonging to the master without
              # creating a ModelReference. Do nothing here.
            when 'master_with_reference'
              ModelReference.create_from_master_with in_master, new_item, force_create:
            else

              unless create_in.is_a?(Hash) && create_in[:specific_record]
                raise FphsException,
                      "Unknown 'in' value in create_reference for config #{config}"
              end

              # A specific instance is the target for the reference from_record
              # Include return: return_result to return the actual instance
              # or use {{{triple curly substitution}}}
              ci = FieldDefaults.calculate_default @item, create_in[:specific_record]
              raise FphsException, "Result for 'in' hash is not an instance" unless ci.is_a? UserBase

              ModelReference.create_with ci, new_item, force_create:
            end

          @item.save_trigger_results['created_references'] << res
          @item.save_trigger_results['created_items'] << new_item
          @item.save_trigger_results['created_results'] << true

          res
        end
      end
    end
  end
end
