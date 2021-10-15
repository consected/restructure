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
      after_commit :reset_model_references

      attr_accessor :action_name

      # a list of embedded items (full data for each model reference)
      # is available, if the #populate_embedded_items method is called
      # otherwise it is nil
      attr_accessor :embedded_items
    end

    def reset_model_references
      @model_references = {}
      @embedded_item = nil
      @creatable_model_references = nil
      @always_embed_item = nil
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
    # @return [Array{ModelReference}]
    def model_references(reference_type: :references, active_only: false, ref_order: nil, use_options_order_by: false, force_reload: nil)
      clear_model_reference_memo if force_reload

      memoize_references({ reference_type: reference_type, active_only: active_only,
                           ref_order: ref_order, use_options_order_by: use_options_order_by }) do
        # NOTE: @config_order_model_references is set by GeneralDataConcerns#as_json to
        #       provide a simple way to indicate model use_options_order_by should be true
        #       for json generation
        use_options_order_by ||= @config_order_model_references

        res = []
        case reference_type
        when :references
          refs = extra_log_type_config.references
        when :e_sign
          refs = extra_log_type_config.e_sign && extra_log_type_config.e_sign[:document_reference]
        end

        break res unless extra_log_type_config && refs

        refs.each do |_ref_key, refitem|
          refitem.each do |ref_type, ref_config|
            f = ref_config[:from]
            without_reference = (ref_config[:without_reference] == true)

            order_by = ref_config[:order_by] if use_options_order_by

            pass_options = {
              to_record_type: ref_type,
              filter_by: ref_config[:filter_by],
              without_reference: without_reference,
              ref_order: ref_order,
              active: active_only,
              order_by: order_by
            }

            got = if f == 'this'
                    ModelReference.find_references self, **pass_options
                  elsif f&.in?(%w[master any])
                    ModelReference.find_references master, **pass_options
                  else
                    msg = "Find references attempted without known :from key: #{f}"
                    Rails.logger.warn msg
                    raise FphsException, msg if Rails.env.development?

                    nil
                  end

            next unless got

            got = got.to_a

            # Filter out the items based on reference specific showable_if rules
            if ref_config[:showable_if]
              got.delete_if do |mr|
                mr.to_record.current_user = current_user
                self.reference = mr.to_record
                !ref_config_performable?(:showable_if, ref_config)
              end
            end

            res += got
          end
        end
        res
      end
    end

    def memoize_references(memokey, &block)
      # Check for a memoized result
      @model_references ||= {}
      return @model_references[memokey] unless @model_references[memokey].nil?

      yield @model_references[memokey] = block.call
    end

    def clear_model_reference_memo
      @creatable_model_references = nil
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
    def creatable_model_references(only_creatables: false, force_reload: nil)
      clear_creatable_model_reference_memo if force_reload

      memoize_creatable_model_references(only_creatables) do
        cre_res = {}
        ref_configs = extra_log_type_config&.references
        break cre_res unless ref_configs

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

              user_can_create = target_object_creatable?(ref_type, ref_config)
              res = { ref_type: ref_type, many: creatable_add_config, ref_config: ref_config } if user_can_create
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
      if mrc.parent == ActivityLog
        elt = ref_config[:add_with] && ref_config[:add_with][:extra_log_type]
        ref_obj = mrc.new(extra_log_type: elt, master: master)
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
    # @param [Symbole] action - one of :showable_if, :creatable_if)
    # @param [Hash] ref_config - single model reference config
    # @return [Boolean | Object] ConditionalAction#calc_action_if result
    def ref_config_performable?(action, ref_config)
      extra_log_type_config.calc_reference_if(ref_config,
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
      memores = @creatable_model_references[memokey]
      return memores if memores

      yield @creatable_model_references[memokey] = block.call
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
          label: label,
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
      without_reference = (ref_config[:without_reference] == true)
      pass_options = {
        to_record_type: ref_type,
        filter_by: filter_by,
        active: true,
        without_reference: without_reference
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
    # A referring record is either set based on the the specific record that
    # the controller tells us is being viewed
    # when an action is performed, or
    # if there is only one model reference we use that instead.
    def referring_record
      return @referring_record == :nil ? nil : @referring_record unless @referring_record.nil?

      res = referenced_from
      if res.length == 1
        @referring_record = res.first&.from_record
        return @referring_record if @referring_record
      end

      @referring_record = :nil
      nil
    end

    #
    # Top referring record is the top record in the reference hierarchy.
    # We iterate through the referring records until we reach the top one and return it.
    # If there are no referring records from the current activity log, return nil
    # @return [UserBase | nil] <description>
    def top_referring_record
      return @top_referring_record == :nil ? nil : @top_referring_record unless @top_referring_record.nil?

      @top_referring_record = next_up = referring_record
      while next_up
        next_up = next_up.referring_record
        @top_referring_record = next_up if next_up
      end

      return @top_referring_record if @top_referring_record

      @top_referring_record = :nil
      nil
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
    # within an ActivityLogsController, which enables forms to submit data cleanly to
    # and embedded item, without having to manually traverse through the model reference.
    # Also, JSON data returned for an activity log will include an *embedded_item* method response
    # so that the embedded item data can be accessed directly within an activity log's data.
    # There are rules that decide which referenced item is the embedded item, dependent on the
    # action being performed by the user and the definition of the model reference in the extra_options
    # configuration.
    # The result is memoized within the activity log instance.
    #
    # We don't have the capability (currently) to handle embedded items that are activity logs,
    # so avoid the issue by explicitly excluding the result.
    # Perhaps this should really be handled within the ActivityLogController, since this limitation
    # is likely due to the UI, but for now retain it here.
    #
    # @todo - refactor and add more comments to make it clearer what the logic is
    # @return [UserBase]
    def embedded_item
      # Handle a symbol that indicates a previous run memoized the value, but was nil.
      # Return nil, not the symbol.
      return @embedded_item == :nil ? nil : @embedded_item unless @embedded_item.nil?

      mrs = model_references
      cmrs = creatable_model_references only_creatables: true

      if embed_action_type == :creating && always_embed_creatable
        # The current action is to display a new form or to create an item from a submitted form.
        # If always_embed_creatable_reference: true has been specified, use this,
        # unless the embeddable item is an activity log or is configured to not be viewable as embedded.
        @embedded_item = build_model_reference([always_embed_creatable.to_sym,
                                                always_embed_creatable_model_reference(cmrs)])
        @embedded_item = nil if creatable_model_not_embeddable?(cmrs)
      elsif always_embed_item(mrs)
      # Do nothing, we've found an embedded item that matches the configured type and set it in the test
      elsif embed_action_type == :creating && cmrs.length == 1
        # The current action is to display a new form or to create an item from a submitted form.
        # and exactly one item is creatable.
        # Build this creatable item, unless the target item is an activity log or is configured not to
        # be viewable as embedded.
        @embedded_item = build_model_reference(cmrs.first)
        @embedded_item = nil if creatable_model_not_embeddable?(cmrs)
      elsif embed_action_type == :creating && cmrs.length > 1
        # If more than one item is creatable, don't use it
        @embedded_item = nil
      elsif embed_action_type == :creating && cmrs.empty? && mrs.length == 1
        # Nothing is creatable, but one reference item has been created. Use the existing one.
        @embedded_item = mrs.first.to_record
      elsif (embed_action_type == :editing || embed_action_type == :viewing) && mrs.empty?
        # If nothing has been embedded, there is nothing to show
        @embedded_item = nil
      elsif embed_action_type == :editing && mrs.length == 1
        # A referenced record exists - the form expects this to be embedded
        # Therefore just use this existing item unless it is configured
        # to not be viewed as embeddable
        @embedded_item = editable_model_not_embeddable?(mrs) ? nil : mrs.first.to_record
      elsif embed_action_type == :viewing && mrs.length == 1 && cmrs.empty?
        # A single referenced record exists and no more are creatable
        # Therefore just use this existing item
        @embedded_item = mrs.first.to_record
      end

      set_embedded_item_current_user

      # Handle memoization
      res = @embedded_item
      @embedded_item ||= :nil
      res
    end

    #
    # Simplify the action_name set by the controller, to
    # get the type we are trying to handle for embedding
    def embed_action_type
      action_name = self.action_name || 'index'

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
    # Raises and exception if there is a always_embed_creatable_reference setting
    # but no corresponding model reference configuration was found
    # @param [Hash] cmrs - creatable model reference config
    # @return [Hash]
    def always_embed_creatable_model_reference(cmrs)
      return unless always_embed_creatable

      @always_embed_creatable_model_reference = cmrs[always_embed_creatable.to_sym]
      return @always_embed_creatable_model_reference if @always_embed_creatable_model_reference

      raise FphsException,
            'Creatable reference not found for always_embed_creatable_reference named ' \
            "#{always_embed_creatable}" \
            "#{always_embed_creatable != always_embed_creatable.singularize ? ' Try singular version' : ''}"
    end

    #
    # If a model reference is configured to to always be embedded
    # (view_options definition states always_embed_reference: matching_model_type)
    # set the @embedded_item if a result was found and return true
    # @param [Hash] - set of model references from #model_references call
    # @return [true | false]
    def always_embed_item(mrs)
      return @always_embed_item unless @always_embed_item.nil?

      @always_embed_item = false
      always_embed_reference = extra_log_type_config.view_options[:always_embed_reference]
      return unless always_embed_reference

      # Get the first model reference for this activity log that matches the record type in the
      # always_embed_reference configuration.
      always_embed = mrs.select { |m| m.to_record_type == always_embed_reference.ns_camelize }.first
      return unless always_embed

      # If a always_embed_reference was matched in the existing model references, use this as the embedded item.
      # It is possible that this will not have matched a record if no model reference of the required
      # type is in existence, so it could still be nil.
      @embedded_item = always_embed.to_record
      @always_embed_item = !!@embedded_item
    end

    #
    # Get the view option for :always_embed_creatable_reference
    def always_embed_creatable
      extra_log_type_config.view_options[:always_embed_creatable_reference]
    end

    #
    # Set the current user for the embedded item
    def set_embedded_item_current_user
      return unless @embedded_item

      if @embedded_item.class.no_master_association
        @embedded_item.current_user ||= master_user
      else
        @embedded_item.master ||= master
        @embedded_item.master.current_user ||= master_user
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
    def creatable_model_not_embeddable?(cmrs)
      return true if @embedded_item.class.parent == ActivityLog

      cmrs.first.last.first.last[:ref_config][:view_as][:new].in?(NotEmbeddedOptions)
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
      mrs.first.to_record_options_config[:view_as][:edit].in?(NotEmbeddedOptions)
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
  end
end
