# frozen_string_literal: true

module Dynamic
  #
  # Provides features to handle model references within activity log implementations.
  # Allows an activity log to
  # - find existing model references
  # - list creatable model references
  # - build new model references to target models
  # - access and embedded item (the target appears directly within the parent's form)
  module ModelReferenceHandler
    extend ActiveSupport::Concern
    include GeneralDataConcerns

    NotEmbeddedOptions = %w[not_embedded select_or_add].freeze

    included do
      # Complete the linkage of an embedded item back to this record
      # Do this both before and after create, to handle the different permutations
      before_create :link_embedded_item
      after_create :link_embedded_item
      after_create :finalize_prepped_embedded_item

      after_commit :reset_model_references

      attr_accessor :action_name, :prepped_embedded_item

      # a list of embedded items (full data for each model reference)
      # is available, if the #populate_embedded_items method is called
      # otherwise it is nil
      attr_accessor :embedded_items
    end

    class_methods do
      #
      # Field name for foreign key on another table referencing this table
      # @return [String] <description>
      def foreign_key_field_name
        "#{table_name.singularize}_id"
      end
    end

    #
    # Clean up the cached values for model_references
    def reset_model_references
      @model_references = nil
      @embedded_items = nil
      @memoize_embedded_items = nil
      @creatable_model_references = nil
      @always_embed_item = nil
      @never_embed_item = nil
      @never_embed_creatable_item = nil
    end

    #
    # Get model references of the current instance
    # NOTE: only model references specified in the references configuration will be returned,
    # independent of the entries in the model_references table. If you do not get back the results
    # you expect, check the references definition to ensure it includes the appropriate
    # add_with and filter_by entries.
    # If the configuration has not set :showable_if then the referenced to-records will be shown
    # If the configuration has set :showable_if then the configuration
    # will be checked to ensure the to-record is viewable. This checks both the current instance
    # and the to_record, accessed through the key :reference.
    # @param [Symbol] reference_type either :references or :e_sign to filter by the specific reference type
    # @param [Boolean] active_only only return active reference records, or those that have also been disabled
    # @param [Hash] ref_order forces the user of a {field: direction} on all references returned, ordering against
    #   the field values in the model_references table (not the target)
    # @param [Boolean] use_options_order_by - use the order_by settings for each reference configuration to order
    #   based on field values in the records pointed to
    # @param [Boolean] force_reload - force any previously memoized results to be ignored
    # @param [Boolean] showable_only - default true, force filtering of results based on *showable_if* config
    # @return [Array{ModelReference}]
    def model_references(reference_type: :references, active_only: false, ref_order: nil, use_options_order_by: false,
                         force_reload: nil, showable_only: true)
      clear_model_reference_memo if force_reload

      memoize_references({ reference_type:, active_only:,
                           ref_order:, use_options_order_by: }) do
        # NOTE: @config_order_model_references is set by GeneralDataConcerns#as_json to
        #       provide a simple way to indicate model use_options_order_by should be true
        #       for json generation
        use_options_order_by ||= @config_order_model_references

        res = []
        refs = references_config_for_type reference_type
        drefs = references_config_for_direct_embed
        if drefs
          refs ||= {}
          refs.merge!(drefs)
        end

        break res unless refs

        refs.each do |_ref_key, refitem|
          refitem.each do |ref_type, ref_config|
            pass_options = {
              to_record_type: ref_type,
              filter_by: ref_config[:filter_by],
              without_reference: ref_config[:without_reference],
              ref_order:,
              active: active_only,
              order_by: use_options_order_by && ref_config[:order_by]
            }

            got = case ref_config[:from]
                  when 'this'
                    ModelReference.find_references self, **pass_options
                  when 'master', 'any'
                    ModelReference.find_references master, **pass_options
                  when 'user_is_creator'
                    pass_options[:ref_created_by_user] = ref_config[:from]
                    ModelReference.find_references self, **pass_options
                  when 'other_user_is_creator'
                    pass_options[:ref_created_by_user] = ref_config[:from]
                    ModelReference.find_references self, **pass_options
                  else
                    msg = "Find references attempted without known :from key: #{ref_config[:from]}"
                    Rails.logger.warn msg
                    raise FphsException, msg if Rails.env.development?

                    next
                  end

            next unless got

            got = got.to_a
            filter_showable_references! got, ref_config if showable_only
            res += got
          end
        end

        res = sort_references(res)
        res
      end
    end

    #
    # Sort the model references results array, using configuration or view_options.sort_references
    #   attribute:
    #   direction:
    #   keep_top:
    # param [Array] res - the result set to sort
    # param [Hash | nil] config - configuration or if nil then
    #                             use the option type configuration view_options.sort_references
    # return [Array]
    def sort_references(res, config = nil)
      vo = config || option_type_config&.view_options&.dig(:sort_references)
      return res unless vo

      smr = vo[:attribute]
      return res unless smr

      smr = smr.to_sym
      sdir = vo[:direction]
      keep_top = vo[:keep_top]
      null_value = vo[:null_value]

      top_item = res.delete_at(0) if keep_top
      res = res.sort_by { |a| a[smr] || null_value }
      res = res.reverse if sdir&.in?(['desc', 'reverse'])
      res.insert(0, top_item) if top_item

      res
    end

    def memoize_references(memokey, &block)
      # Check for a memoized result
      @model_references ||= {}
      return @model_references[memokey] if @model_references.key?(memokey)

      @model_references[memokey] = block.call
    end

    def clear_model_reference_memo
      @creatable_model_references = nil
      @model_references = nil
    end

    #
    # Gets the references configuration Hash for the specified reference_type
    # @param [Symbol] reference_type - :references | :e_sign
    # @return [Hash]
    def references_config_for_type(reference_type)
      return unless option_type_config

      case reference_type
      when :references
        option_type_config.references
      when :e_sign
        option_type_config.e_sign && option_type_config.e_sign[:document_reference]
      end
    end

    #
    # Gets the references configuration Hash for a direct embed, if configured
    # and the current instance has an id for the reference
    # @return [Hash]
    def references_config_for_direct_embed
      return unless direct_embed?

      dec = direct_embed_config
      rn = dec && dec[:resource_name]
      return unless rn

      rin = dec[:resource_item_name]

      filter_by = if dec.key? :target_fk
                    # No resource_id was specified, so we filter on the target table having a field pointing to this one
                    { dec[:target_fk] => id || -1 }
                  elsif dec.key? :resource_id
                    { "id": dec[:resource_id] }
                  end
      # A resource_id was specified, either based on a field being present, or from the option config
      # If either of these are defined but returned nil, we have already forced the result to be -1
      # to prevent a full table scan of the target

      {
        rin => {
          rin => {
            from: 'any',
            to_record_type: rin,
            filter_by:,
            without_reference: true,
            many: 'direct_embed',
            ref_config: { embed_resource_name: rin },
            limit: dec[:limit],
            add: dec[:add]
          }
        }
      }
    end

    #
    # Filter out the items based on reference specific showable_if rules.
    # Deletes items directly from ref_list.
    # @param [Array] ref_list - array of model reference results
    # @param [Hash] ref_config - references configuration
    def filter_showable_references!(ref_list, ref_config)
      return unless ref_config[:showable_if]

      ref_list.delete_if do |mr|
        mr.to_record.current_user = current_user
        self.reference = mr.to_record
        !ref_config_performable?(:showable_if, ref_config)
      end
    end

    #
    # List model reference configurations that are creatable by the current user
    # By default will return all reference configurations, where the entry for the reference
    # has a value of an empty hash if not creatable, or a hash containing a configuration
    # describing how the creation can be performed.
    # The result is memoized (against the only_creatables value) for performance.
    #
    # @param [Boolean] only_creatables - will return only the creatable model references if true
    # @return [Hash] <description>
    def creatable_model_references(only_creatables: false, force_reload: nil, current_admin_sample: nil)
      clear_creatable_model_reference_memo if force_reload

      memoize_creatable_model_references(only_creatables) do
        cre_res = {}
        ref_configs = option_type_config&.references || {}

        if direct_embed?

          drefs = references_config_for_direct_embed
          ref_configs.merge!(drefs) if drefs
        end

        break cre_res if ref_configs&.empty?

        ref_configs.each do |ref_key, refitem|
          refitem.each do |ref_type, ref_config|
            next unless ref_config_performable?(:creatable_if, ref_config)

            res = {}

            creatable_add_config = creatable_add_config_for(ref_type, ref_config)
            if creatable_add_config

              if create_from_activity_selector?(ref_config)
                cre_res.merge! creatables_for_activity_selector(ref_type, ref_config, creatable_add_config)
                # All items have been added. Prevent the default activity log item being tested below.
                next
              end

              user_can_create = current_admin_sample || target_object_creatable?(ref_type, ref_config)
              res = { ref_type:, many: creatable_add_config, ref_config: } if user_can_create
            end

            cre_res[ref_key] = { ref_type => res } if res[:ref_type] || !only_creatables
          end
        end

        cre_res
      end
    end

    #
    # Check that the target object, based on the ref_config, is creatable by the current user.
    # If it represents an ActivityLog then we use an instance based on the activity extra log type,
    # specified in the { add_with: extra_log_type } configuration.
    # Otherwise, it is a dynamic model / core model.
    # With this object we check the user has access to create it.
    # @param [String] ref_type - type of referenced model
    # @param [Hash] ref_config - current reference config
    # @return [UserBase]
    def target_object_creatable?(ref_type, ref_config)
      mrc = class_for_reference_type(ref_type)

      if mrc&.class_parent_name == 'ActivityLog'

        elt = ref_config[:add_with] && ref_config[:add_with][:extra_log_type]
        ref_obj = mrc.new(extra_log_type: elt, master:)
      else
        attrs = {}
        if mrc.no_master_association
          attrs[:current_user] = master_user
        else
          attrs[:master] = master
        end
        ref_obj = mrc.new attrs
      end

      ref_obj&.allows_current_user_access_to?(:create)
    end

    #
    # Check if action defined for model reference item. If so, evaluate the conditions,
    # otherwise just return default of true to say it is always performable.
    # @param [Symbol] action - one of :showable_if, :creatable_if)
    # @param [Hash] ref_config - single model reference config
    # @return [Boolean | Object] ConditionalAction#calc_action_if result
    def ref_config_performable?(action, ref_config)
      return true unless option_type_config

      option_type_config.calc_reference_if(ref_config,
                                           action,
                                           self,
                                           default_if_no_config: true)
    end

    #
    # The class corresponding to the reference type.
    # Raises exception if the ref_type is invalid.
    # @param [String] ref_type
    # @return [UserBase]
    def class_for_reference_type(ref_type)
      mrc = ModelReference.to_record_class_for_type(ref_type)
      return mrc unless mrc.nil?

      raise FphsException, "Reference type is invalid: #{ref_type}"
    end

    def memoize_creatable_model_references(only_creatables, &block)
      # Check for a memoized result
      @creatable_model_references ||= {}
      memokey = "only_creatables_#{only_creatables}"
      return @creatable_model_references[memokey] if @creatable_model_references.key?(memokey)

      @creatable_model_references[memokey] = block.call
    end

    def clear_creatable_model_reference_memo
      @creatable_model_references = nil
    end

    #
    # Does this reference config require the creatable items to
    # come from an {type_config: activity_selector: config}?
    # If so
    # @param [Hash] ref_config - current reference configuration
    # @return [true | false]
    def create_from_activity_selector?(ref_config)
      ref_config[:type_config]&.keys&.first == :activity_selector
    end

    #
    # Collect up all the creatable configurations for an activity_selector configuration
    # @param [Hash] ref_config
    # @return [Hash]
    def creatables_for_activity_selector(ref_type, ref_config, creatable_add_config)
      cre_res = {}
      activity_selector_config = ref_config[:type_config][:activity_selector]

      # The creatable model instances that appear in the activity_selector config
      # The user can create this type if a configuration is not nil, so we just return a #compact Hash
      activity_selector_creatables = creatables.compact.slice(*activity_selector_config.keys)
      activity_selector_creatables.each do |activity_key, model_name|
        label = activity_selector_config[activity_key]

        elt_ref_config = ref_config.merge(
          label:,
          to_record_label: label,
          add_with: {
            extra_log_type: activity_key.to_s
          },
          filter_by: {
            extra_log_type: '__return_nothing__'
          }
        )
        res = { ref_type: model_name, many: creatable_add_config, ref_config: elt_ref_config }
        cre_res["#{ref_type}_#{activity_key}".to_sym] = { ref_type => res }
      end

      cre_res
    end

    #
    # Return the model reference add: config if the reference is creatable
    # based on the provided configuration and whether it meets the
    # limit / one / many requirements.
    # @return [String]
    def creatable_add_config_for(ref_type, ref_config)
      # The config for adding a model reference
      add_config = ref_config[:add]

      # Additional options to apply to #find_reference calls
      filter_by = ref_config[:filter_by]
      without_reference = ref_config[:without_reference]
      ref_created_by_user = ref_config[:from] if ref_config[:from].in?(['user_is_creator', 'other_user_is_creator'])
      pass_options = {
        to_record_type: ref_type,
        filter_by:,
        active: true,
        without_reference:,
        ref_created_by_user:
      }

      if add_config == 'many'
        # Many may be added. If there is a limit defined, check that
        # the number of references does not yet match the limit.
        limit = ref_config[:limit]
        under_limit =
          if limit.is_a?(Integer)
            ModelReference.find_references(master, **pass_options).length < limit
          else
            true
          end
        creatable_add_config = add_config if under_limit
      elsif add_config == 'one_to_master'
        # One item may be added to the master. If no references from the master exist, we can add one.
        creatable_add_config = add_config if ModelReference.find_references(master, **pass_options).empty?
      elsif add_config == 'one_to_this'
        # One item may be added to the current instance. If no references from this item exist, we can add one.
        creatable_add_config = add_config if ModelReference.find_references(self, **pass_options).empty?
      elsif add_config.present?
        # The configuration used a bad config value.
        raise FphsException, "Unknown add type for creatable_model_references: #{add_config}"
      end
      creatable_add_config
    end

    #
    # Use a provided creatable model reference to make a new item
    # Initialize attributes with any filter_by configurations, to ensure the
    # item is set up correctly to be picked up again later
    def build_model_reference(creatable_model_ref, optional_params: {})
      cmrdef = creatable_model_ref.last.first.last
      cmrdef.with_indifferent_access

      ref_config = cmrdef[:ref_config].with_indifferent_access

      # Ensure that the filter_by attributes are used to generate the referenced item,
      # otherwise the filter will not work correctly after creation (since the fields won't be set)
      # Also include additional add_with items if provided
      fb = ref_config[:filter_by] || {}
      aw = ref_config[:add_with] || {}
      tot = fb.merge(aw)

      optional_params.merge!(tot)

      cmrdef[:ref_type].ns_camelize.constantize.new optional_params
    end

    #
    # For NfsStore model references, get the container referenced from this activity log
    # @return [NfsStore::Manage::Container | nil]
    def container
      mr = model_references.select { |mra| mra.to_record_type == 'NfsStore::Manage::Container' }.first
      return unless mr

      mr.to_record
    end

    #
    # Item targeted by the most recent model reference, if there is one.
    # @return [UserBase | nil] <description>
    def latest_reference
      return @latest_reference == :nil ? nil : @latest_reference unless @latest_reference.nil?

      @latest_reference = model_references(ref_order: { id: :desc }).first&.to_record

      return @latest_reference if @latest_reference

      @latest_reference = :nil
      nil
    end

    #
    # Return an "embedded item", which is a standard model that appears embedded directly
    # within a parent activity log's form. This ties in tightly with the handling of this
    # within an EmbeddedItemHandler, which enables forms to submit data cleanly to
    # an embedded item, without having to manually traverse through the model reference.
    # Also, JSON data returned for an activity log will include an *embedded_item* method response
    # so that the embedded item data can be accessed directly within an activity log's data.
    # There are rules that decide which referenced item is the embedded item, dependent on the
    # action being performed by the user and the definition of the model reference in the extra_options
    # configuration.
    # The result is memoized within the activity log instance.
    #
    # We don't have the capability (currently) to handle embedded items that are activity logs,
    # so avoid the issue by explicitly excluding the result.
    # Perhaps this exclusion should really be handled within the EmbeddedItemHandler, since this limitation
    # is likely due to the UI, but for now retain it here.
    #
    # @return [UserBase]
    def embedded_item(embed_action_type: nil, only_creatables: true, force_reload: nil, current_admin_sample: nil)
      embed_action_type ||= self.embed_action_type

      clear_embedded_item_memo if force_reload

      memoize_embedded_item do
        res = nil
        mrs = model_references(force_reload:)
        cmrs = creatable_model_references(only_creatables:, force_reload:, current_admin_sample:)

        if never_embed_item || embed_action_type == :creating && never_embed_creatable_item
          # Do nothing - we have been told to never embed
        elsif embed_action_type == :creating && always_embed_creatable
          # The current action is to display a new form or to create an item from a submitted form.
          # If always_embed_creatable_reference: true has been specified, use this,
          # unless the embeddable item is an activity log or is configured to not be viewable as embedded.
          res = build_model_reference([always_embed_creatable.to_sym,
                                       always_embed_creatable_model_reference(cmrs)])
          res = nil if creatable_model_not_embeddable?(cmrs, res)
        elsif (res = always_embed_item(mrs))
          # Do nothing, we've found an embedded item that matches the configured type and set it in the condition above
        elsif embed_action_type == :creating && cmrs.length == 1
          # The current action is to display a new form or to create an item from a submitted form.
          # and exactly one item is creatable.
          # Build this creatable item, unless the target item is an activity log or is configured not to
          # be viewable as embedded.
          res = build_model_reference(cmrs.first)
          res = nil if creatable_model_not_embeddable?(cmrs, res)
        elsif embed_action_type == :creating && cmrs.length > 1
          # If more than one item is creatable, don't use it
          res = nil
        elsif embed_action_type == :creating && cmrs.empty? && mrs.length == 1
          # Nothing is creatable, but one reference item has been created. Use the existing one.
          res = mrs.first.to_record
        elsif %i[editing viewing].include?(embed_action_type) && mrs.empty?
          # If nothing has been embedded, there is nothing to show
          res = nil
        elsif embed_action_type == :editing && mrs.length == 1
          # A referenced record exists - the form expects this to be embedded
          # Therefore just use this existing item unless it is configured
          # to not be viewed as embeddable
          res = editable_model_not_embeddable?(mrs) ? nil : mrs.first.to_record
        elsif embed_action_type == :viewing && mrs.length == 1 && cmrs.empty?
          # A single referenced record exists and no more are creatable
          # Therefore just use this existing item
          res = mrs.first.to_record
        end

        apply_embedded_item_current_user(res)
        res
      end
    end

    #
    # Create an embedded item inside the current instance, setting up a
    # model_references record if needed (skipped if directly embedded)
    # @param [Hash] attrs
    # @param [true|false] force_create
    # @param [true|false] force_not_valid
    # @return [UserBase] embedded item that was created
    def create_embedded_item(attrs, force_create: nil, force_not_valid: nil)
      ei = embedded_item(embed_action_type: :creating)
      return unless ei

      ei.ignore_configurable_valid_if = force_not_valid

      if force_create
        ei.send(:force_write_user)
        ei.force_save!
      end

      ei.update!(attrs)
      ModelReference.create_with self, ei unless direct_embed?
      ei
    end

    #
    # An embedded item may need its attributes set before the parent save
    # method is called
    def prep_embedded_item(attrs, force_create: nil, force_not_valid: nil)
      @prep_embedded_item = {
        attrs:,
        force_create:,
        force_not_valid:
      }
    end

    #
    # Apply the details added to prep the embedded item
    def apply_prepped_embedded_item(use_embedded_item = nil)
      return unless @prep_embedded_item

      attrs = @prep_embedded_item[:attrs]
      force_create = @prep_embedded_item[:force_create]
      force_not_valid = @prep_embedded_item[:force_not_valid]

      self.action_name = 'create'
      ei = use_embedded_item || embedded_item(embed_action_type: :creating)
      return unless ei

      ei.ignore_configurable_valid_if = force_not_valid
      ei.send(:force_write_user)

      ei.force_save! if force_create

      if direct_embed?
        ei.assign_attributes(attrs)
      else
        ei.update(attrs)
      end
      self.action_name = 'index'

      @prepped_embedded_item = ei
    end

    #
    # After creating, a prepped embedded item may need its model reference created
    # unless it is a directly embedded item
    def finalize_prepped_embedded_item
      return if !@prepped_embedded_item || direct_embed?

      prepped_embedded_item.save!
      ModelReference.create_with self, @prepped_embedded_item
    end

    #
    # Update an embedded item inside the current instance
    # @param [Hash] attrs
    # @param [true|false] force_not_editable_save
    # @param [true|false] force_not_valid
    # @return [UserBase] embedded item that was updated
    def update_embedded_item(attrs, force_not_editable_save: nil, force_not_valid: nil)
      self.action_name = 'update'
      ei = embedded_item
      return unless ei

      ei.ignore_configurable_valid_if = force_not_valid
      ei.force_save! if force_not_editable_save
      ei.update!(attrs)
      self.action_name = 'index'
      ei
    end

    def memoize_embedded_item(&block)
      # Check for a memoized result
      @memoize_embedded_items ||= {}
      memokey = "embedded_item_#{embed_action_type}"
      return @memoize_embedded_items[memokey] if @memoize_embedded_items.key?(memokey)

      @memoize_embedded_items[memokey] = block.call
    end

    def clear_embedded_item_memo
      @memoize_embedded_items = nil
    end

    #
    # Simplify the action_name set by the controller, to
    # get the type we are trying to handle for embedding.
    # If a current #action_name is set, use it, otherwise
    # if the instance is not persisted, assume we are in a new action,
    # or if it is persisted then default to 'index' to force viewing
    def embed_action_type
      action_name = self.action_name || (!persisted? && 'new') || 'index'

      case action_name
      when 'new', 'create'
        :creating
      when 'edit', 'update'
        :editing
      when 'show', 'index'
        :viewing
      end
    end

    #
    # Get the model reference config, for the model that has
    # been specified to alway embed during creation.
    # Raises an exception if there is a always_embed_creatable_reference setting
    # but no corresponding model reference configuration was found
    # @param [Hash] cmrs - creatable model reference config
    # @return [Hash]
    def always_embed_creatable_model_reference(cmrs)
      return {} unless always_embed_creatable

      @always_embed_creatable_model_reference = cmrs[always_embed_creatable.to_sym]
      return @always_embed_creatable_model_reference if @always_embed_creatable_model_reference

      raise FphsException,
            'Creatable reference not found or not creatable for always_embed_creatable_reference named ' \
            "#{always_embed_creatable}" \
            "#{always_embed_creatable != always_embed_creatable.singularize ? ' Try singular version' : ''}"
    end

    #
    # If a model reference is configured to to always be embedded
    # (view_options definition states always_embed_reference: matching_model_type)
    # @param [Hash] - set of model references from #model_references call
    # @return [truthy]
    def always_embed_item(mrs)
      return @always_embed_item if @always_embed_item
      return nil if @always_embed_item == false

      @always_embed_item = false
      return unless option_type_config&.view_options

      always_embed_reference = option_type_config.view_options[:always_embed_reference]
      return unless always_embed_reference

      # Get the first model reference for this activity log that matches the record type in the
      # always_embed_reference configuration.
      always_embed = mrs.select { |m| m.to_record_type == always_embed_reference.ns_camelize }.first
      return unless always_embed

      # If a always_embed_reference was matched in the existing model references, use this as the embedded item.
      # It is possible that this will not have matched a record if no model reference of the required
      # type is in existence, so it could still be nil.
      @always_embed_item = always_embed.to_record
    end

    #
    # Prevent any items from being shown as embedded
    def never_embed_item
      return @never_embed_item unless @never_embed_item.nil?

      aer = option_type_config&.view_options&.dig(:always_embed_reference)
      @never_embed_item = (aer == 'never')
    end

    #
    # Prevent any items from being shown as embedded during creation of the
    # activity log type
    def never_embed_creatable_item
      return @never_embed_creatable_item unless @never_embed_creatable_item.nil?

      aer = option_type_config&.view_options&.dig(:always_embed_creatable_reference)
      @never_embed_creatable_item = (aer == 'never')
    end

    #
    # Get the view option for :always_embed_creatable_reference
    def always_embed_creatable
      return unless option_type_config

      option_type_config.view_options[:always_embed_creatable_reference]
    end

    #
    # Set the current user for the embedded item
    def apply_embedded_item_current_user(res)
      return unless res

      if res.class.no_master_association
        res.current_user ||= master_user
      else
        res.master ||= master
        res.master.current_user ||= master_user
      end
    end

    #
    # An item is not embeddable if it is an activity log. Otherwise,
    # find the view_as configuration for the first creatable reference, if there is one
    # for :new.
    # Only returns true if :new is defined and is one of the not embeddable types.
    # If not defined, it is considered embeddable.
    # @param [Hash] cmrs - result of #creatable_model_references
    # @return [true| nil]
    def creatable_model_not_embeddable?(cmrs, item)
      return true if item.class.class_parent_name == 'ActivityLog'

      cmrs.first.last.first.last.dig(:ref_config, :view_as, :new)&.in?(NotEmbeddedOptions)
    rescue StandardError
      nil
    end

    #
    # Find the view_as configuration for the first model reference, if there is one
    # for :edit.
    # Only returns true if :edit is defined and is one of the not embeddable types.
    # If not defined, it is considered embeddable.
    # @param [Hash] mrs - result of #model_references
    # @return [true| nil]
    def editable_model_not_embeddable?(mrs)
      mrs.first.to_record_options_config&.dig(:view_as, :edit)&.in?(NotEmbeddedOptions)
    rescue StandardError
      nil
    end

    #
    # Populate a list of embedded items, a full record for
    # each active model reference
    # @return [Array{UserBase}]
    def populate_embedded_items
      @embedded_items = []
      model_references(active_only: true).each do |mr|
        @embedded_items << mr.to_record
      end
    end

    #
    # Does an extra options configuration or an embed_resource_name field
    # indicate that we will directly embed a resource?
    # @return [true] <description>
    def direct_embed?
      option_type_config&.embed || respond_to?(:embed_resource_name)
    end

    #
    # The direct embed configuration to make an embedded item definition
    # look like an option type config *references:* definition when
    # used in #model_reference / #creatable_model_references
    # This method uses extra options config or the embed_resource_name field
    # The return is a Hash
    # {embed_type:, resource_name:, :resource_item_name, add:, limit:, :target_fk, :resource_id}
    # Returns nil if a direct embed definition is not matched.
    # @return [Hash|nil]
    def direct_embed_config
      res = option_type_config&.embed

      if res
        res[:embed_type] = 'option_type_config'
      elsif respond_to?(:embed_resource_name) && embed_resource_name
        res = { embed_type: 'field', resource_name: embed_resource_name }
        res[:resource_id] = embed_resource_id if respond_to?(:embed_resource_id)
      else
        return
      end

      rn = res[:resource_name]
      return unless rn

      embed_resource = Resources::Models.find_by(resource_name: rn)
      raise FphsException, "embed_resource not found for #{rn}" unless embed_resource

      fk = self.class.foreign_key_field_name
      res[:target_fk] = fk if !res.key?(:resource_id) && embed_resource.model.attribute_names.include?(fk)

      res[:resource_item_name] = embed_resource.resource_item_name
      res[:add] = 'many'
      res[:limit] ||= 1

      res
    end

    #
    # After creating a new record, if it has a directly embedded item now is the time to
    # link it with its parent. This may be through fields in either the current record or
    # the target embedded item, depending on the configuration. We can only do this when
    # either record has been persisted with an id.
    def link_embedded_item
      ei = embedded_item(embed_action_type: :creating)
      apply_prepped_embedded_item ei

      link_new_embedded_item(ei) if direct_embed?
    end

    #
    # When a new dynamic record is persisted with an embedded item, the
    # appropriate fields need to be set to create the link.
    # This is omnipotent and may safely be called multiple times without
    # breaking existing links.
    # The method will be called both before and after creation of the current instance
    # allowing the appropriate setting of fields in either the current instance and/or
    # the embedded item.
    # If the embed type is 'field' (has an embed_resource_name) amd has an
    # embed_resource_id field, set the latter.
    # Otherwise, if the config says the direct embed item has a foreign key
    # field back to this instance, set that foreign key field in the new embedded item
    # In either case, if the target id field is already set and the value is not
    # negative (we often default embedded item id values to -1 to protect
    # against full table searches) then skip the update.
    def link_new_embedded_item(new_embedded_item)
      return unless new_embedded_item

      dec = direct_embed_config

      if dec[:embed_type] == 'field' && respond_to?(:embed_resource_id) && !persisted?
        # The embed type has fields embed_resource_name and embed_resource_id
        # If the embed_resource_id is not already set and the new embed item id
        # is valid then set the embed_resource_id in the current instance with the
        # new embedded item's id
        return if embed_resource_id

        new_embedded_item.save! unless new_embedded_item.persisted?
        new_id = new_embedded_item.id
        return if !new_id || new_id < 0

        self.embed_resource_id = new_id
        return
      end

      target_fk = dec[:target_fk]
      unless target_fk
        # Make sure the new embedded item is saved to ensure it is created
        new_embedded_item.save!
        # Return if the configuration says there is not a foreign key field in the new embedded item
        return
      end

      fk_val = new_embedded_item.attributes[target_fk]
      # Exit if this instance does not have a valid id or if the foreign
      # key field in the new embedded item is already set
      return if (!id || id < 0) || (fk_val && fk_val >= 0)

      new_embedded_item.update!(target_fk => id)
    end
  end
end
