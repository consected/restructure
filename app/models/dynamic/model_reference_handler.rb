# frozen_string_literal: true

module Dynamic
  module ModelReferenceHandler
    extend ActiveSupport::Concern
    include GeneralDataConcerns

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
    end

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
    def model_references(reference_type: :references, active_only: false, ref_order: nil, use_options_order_by: false)
      mr_key = { reference_type: reference_type, active_only: active_only,
                 ref_order: ref_order, use_options_order_by: use_options_order_by }
      @model_references ||= {}
      return @model_references[mr_key] unless @model_references[mr_key].nil?

      use_options_order_by ||= @config_order_model_references

      res = []
      case reference_type
      when :references
        refs = extra_log_type_config.references
      when :e_sign
        refs = extra_log_type_config.e_sign && extra_log_type_config.e_sign[:document_reference]
      end

      @model_references[mr_key] = res
      return res unless extra_log_type_config && refs

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
              !extra_log_type_config.calc_reference_if(ref_config, :showable_if, self)
            end
          end

          res += got
        end
      end
      @model_references[mr_key] = res
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
    def creatable_model_references(only_creatables: false)
      # Check for a memoized result
      @creatable_model_references ||= {}
      memokey = "only_creatables_#{only_creatables}"
      memores = @creatable_model_references[memokey]
      return memores if memores

      cre_res = {}
      return cre_res unless extra_log_type_config&.references

      extra_log_type_config.references.each do |ref_key, refitem|
        refitem.each do |ref_type, ref_config|
          res = {}
          ires = nil

          # Check if creatable_if has been defined on the reference configuration
          # and if it evaluates to true

          ci_res = extra_log_type_config.calc_reference_if ref_config, :creatable_if, self
          fb = ref_config[:filter_by]

          next unless ci_res

          a = ref_config[:add]
          without_reference = (ref_config[:without_reference] == true)

          pass_options = {
            to_record_type: ref_type,
            filter_by: fb,
            active: true,
            without_reference: without_reference
          }

          if a == 'many'
            l = ref_config[:limit]

            under_limit =
              if l.is_a?(Integer)
                (ModelReference.find_references(master, **pass_options).length < l)
              else
                true
              end

            ires = a if under_limit
          elsif a == 'one_to_master'
            ires = a if ModelReference.find_references(master, **pass_options).empty?
          elsif a == 'one_to_this'
            ires = a if ModelReference.find_references(self, **pass_options).empty?
          elsif a.present?
            raise FphsException, "Unknown add type for creatable_model_references: #{a}"
          end

          if ires
            # Check if the user has access to create the item

            mrc = ModelReference.to_record_class_for_type(ref_type)
            raise FphsException, "Reference type is invalid: #{ref_type}" if mrc.nil?

            rct = ref_config[:type_config]

            if rct&.keys&.first == :activity_selector
              rct_conf = rct.first.last
              creatables.compact.each do |elt, resname|
                next unless elt.in? rct_conf.keys

                # The user can create this type if a resname is set
                label = rct_conf[elt]

                elt_ref_config = ref_config.merge({
                                                    label: label,
                                                    to_record_label: label,
                                                    add_with: {
                                                      extra_log_type: elt.to_s
                                                    },
                                                    filter_by: {
                                                      extra_log_type: '__return_nothing__'
                                                    }
                                                  })
                res = { ref_type: resname, many: ires, ref_config: elt_ref_config }
                cre_res["#{ref_type}_#{elt}"] = { ref_type => res }
              end
              # All items have been added. Prevent the default activity log item being tested below.
              next

            elsif mrc.parent == ActivityLog
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

            user_can_create = ref_obj&.allows_current_user_access_to? :create
            res = { ref_type: ref_type, many: ires, ref_config: ref_config } if user_can_create

          end

          cre_res[ref_key] = { ref_type => res } if res[:ref_type] || !only_creatables
        end
      end
      @creatable_model_references[memokey] = cre_res
    end

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

    # Get the container referenced from this activity log
    # @return [NfsStore::Manage::Container | nil]
    def container
      mr = model_references.select { |mra| mra.to_record_type == 'NfsStore::Manage::Container' }.first
      return unless mr

      mr.to_record
    end

    # A referring record is either set based on the the specific record that the controller say is being viewed
    # when an action is performed, or
    # if there is only one model reference we use that instead.
    def referring_record
      return @referring_record == :nil ? nil : @referring_record unless @referring_record.nil?

      res = referenced_from
      @referring_record = res.first&.from_record
      return @referring_record if @referring_record && res.length == 1

      @referring_record = :nil
      nil
    end

    # Top referring record is the top record in the reference hierarchy
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

    def latest_reference
      return @latest_reference == :nil ? nil : @latest_reference unless @latest_reference.nil?

      @latest_reference = model_references(ref_order: { id: :desc }).first&.to_record

      return @latest_reference if @latest_reference

      @latest_reference = :nil
      nil
    end

    def embedded_item
      return @embedded_item == :nil ? nil : @embedded_item unless @embedded_item.nil?

      action_name = self.action_name || 'index'

      oi = self

      not_embedded_options = %w[not_embedded select_or_add]

      mrs = oi.model_references

      cmrs = oi.creatable_model_references only_creatables: true

      always_embed_reference = oi.extra_log_type_config.view_options[:always_embed_reference]
      always_embed_creatable = oi.extra_log_type_config.view_options[:always_embed_creatable_reference]

      if always_embed_reference
        always_embed_item = mrs.select { |m| m.to_record_type == always_embed_reference.ns_camelize }.first
      end

      if always_embed_item
        # Always embed if instructed to do so by the options config
        @embedded_item = always_embed_item.to_record
      end

      if always_embed_item && @embedded_item
        # Do nothing
      elsif action_name.in?(%w[new create]) && always_embed_creatable
        # If creatable has been specified as always embedded, use this, unless the embeddable item is an activity log.
        cmr_view_as = begin
          cmrs.first.last.first.last[:ref_config][:view_as]
        rescue StandardError
          nil
        end
        embed_cmrs = cmrs[always_embed_creatable.to_sym]
        unless embed_cmrs
          raise FphsException,
                'Creatable reference not found for always_embed_creatable_reference named ' \
                "#{always_embed_creatable}" \
                "#{always_embed_creatable != always_embed_creatable.singularize ? ' Try singular version' : ''}"
        end
        @embedded_item = oi.build_model_reference [always_embed_creatable.to_sym, embed_cmrs]
        if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
          @embedded_item = nil
        end
      elsif action_name.in?(%w[new create]) && cmrs.length == 1
        # If exactly one item is creatable, use this, unless the embeddable item is an activity log.
        cmr_view_as = begin
          cmrs.first.last.first.last[:ref_config][:view_as]
        rescue StandardError
          nil
        end
        @embedded_item = oi.build_model_reference cmrs.first
        if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
          @embedded_item = nil
        end
      elsif action_name.in?(%w[new create]) && cmrs.length > 1
        # If more than one item is creatable, don't use it
        @embedded_item = nil
      elsif action_name.in?(%w[new create]) && cmrs.empty? && mrs.length == 1
        # Nothing is creatable, but one has been created. Use the existing one.
        @embedded_item = mrs.first.to_record
      elsif action_name.in?(%w[edit update show index]) && mrs.empty?
        # If nothing has been embedded, there is nothing to show
        @embedded_item = nil
      elsif action_name.in?(%w[edit update]) && mrs.length == 1
        # A referenced record exists - the form expects this to be embedded
        # Therefore just use this existing item
        @embedded_item = mrs.first.to_record
        mr_view_as = begin
          mrs.first.to_record_options_config[:view_as]
        rescue StandardError
          nil
        end
        @embedded_item = nil if mr_view_as && mr_view_as[:edit].in?(not_embedded_options)

      elsif action_name.in?(%w[show index]) && mrs.length == 1 && cmrs.empty?
        # A referenced record exists and no more are creatable
        # Therefore just use this existing item
        @embedded_item = mrs.first.to_record

      end

      if @embedded_item
        if @embedded_item.class.no_master_association
          @embedded_item.current_user ||= oi.master_user
        else
          @embedded_item.master ||= oi.master
          @embedded_item.master.current_user ||= oi.master_user
        end
      end

      res = @embedded_item
      @embedded_item ||= :nil
      res
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
