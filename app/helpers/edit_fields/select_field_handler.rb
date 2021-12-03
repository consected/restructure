# frozen_string_literal: true

module EditFields
  class SelectFieldHandler
    attr_accessor :form_object_instance, :assoc_or_class_name,
                  :value_attr, :label_attr, :group_split_char

    #
    # Gets the #data for each record for a select on an association or class name
    # @param [UserBase] form_object_instance the current instance for the form object
    # @param [String] assoc_or_class_name a master association name or an underscored class name to select from
    # @param [Symbol] value_attr names the attribute to be returned as the value of a selection - default :data
    # @return [Array(String, Array(Array, Array))] a human name string and a list of data from the matched records
    def self.list_record_data_for_select(form_object_instance, assoc_or_class_name,
                                         value_attr: :data, label_attr: :data, group_split_char: nil)

      sf = SelectFieldHandler.new
      sf.form_object_instance = form_object_instance
      sf.assoc_or_class_name = assoc_or_class_name
      sf.value_attr = value_attr
      sf.label_attr = label_attr
      sf.group_split_char = group_split_char
      sf.generate_record_data
    end

    #
    # Group selections based on splitting on the *group_split_char*
    # If the split character is not specified, just return the original array
    # @param [Array] reslist - a standard select options array
    # @param [String | nil] group_split_char
    # @return [Array] - a standard select options array
    def self.record_results_grouping(reslist, group_split_char)
      return reslist unless group_split_char.present?

      grouped = {}
      reslist.each do |rec|
        r = rec.first || ''
        val = rec.last

        rs = r.split(group_split_char, 2)

        if rs.length == 2
          group = rs.first.strip
          new_r = [rs.last.strip, val]
        else
          group = ''
          new_r = [r, val]
        end

        grouped[group] ||= []
        grouped[group] << new_r
      end
      grouped.to_h
    end

    #
    # Gets the #data for each record for a select on an association or class name.
    # Only called by SelectFieldHandler.list_record_data_for_select after initialization
    def generate_record_data
      cl, reslist = record_data_class_and_results

      if cl.nil?
        logger.warn "Failed to find valid class name for #{assoc_or_class_name}"
      elsif cl.attribute_names.include?('rank')
        reslist_data = list_for_rank(reslist)
      elsif label_attr == :data || value_attr == :data
        reslist_data = list_for_complex_attributes(reslist)
      else
        reslist_data = list_for_defined_attributes(reslist, cl)

      end

      human_name = cl&.human_name

      # In case no results were found
      reslist_data ||= []

      reslist_data = self.class.record_results_grouping(reslist_data, group_split_char)

      [human_name, reslist_data]
    end

    private

    #
    # Get the class and result set for a select_record field, based on the source instance
    # and the supplied association or table name
    # @return [Array{UserBase, ActiveRecord::Relation}]
    def record_data_class_and_results
      assoc_name = assoc_or_class_name.pluralize

      if Master.get_all_associations.include?(assoc_name)
        # We matched one of the possible classes an activity log be used with (really these are master associations)
        reslist = form_object_instance.master.send(assoc_name)

        cl = reslist.first&.class
      elsif (ActivityLog.all_valid_item_and_rec_types - ActivityLog.use_with_class_names).include? assoc_or_class_name
        # We matched one of the valid item and rec_types
        ActivityLog.use_with_class_names.each do |ucn|
          next unless assoc_or_class_name.start_with?(ucn)

          # Ensure that the class supporting the association has loaded
          # Item classes such as PlayerContact don't always load until referenced in the application.
          # When they provide dynamically generated rec_type associations in their setup the associations won't exist
          # Just touch the base class to get it set up, and the dynamic associations to be configured.
          ucn.camelize.constantize
          reslist = form_object_instance.master
                                        .send(assoc_or_class_name.pluralize)
                                        .where(rec_type: assoc_or_class_name.sub(/^#{ucn}_/, ''))
          break
        end

        cl = reslist.first&.class
      else
        # Just get the resource by its resource name or alternatively its table name
        cl = Resources::Models.find_by(resource_name: assoc_name) || Resources::Models.find_by(table_name: assoc_name)

        if cl
          cl = cl[:model]
          reslist = cl.all
        end
      end
      reslist = reslist.active if reslist.respond_to?(:active)
      reslist = reslist.distinct if reslist.respond_to?(:distinct)

      [cl, reslist]
    end

    #
    # Generate the result list for a model that contains a rank
    # @param [ActiveRecord::Relation] reslist <description>
    # @return [Array]
    def list_for_rank(reslist)
      reslist = reslist.unscope(:order).order(rank: :desc)
      reslist.all.map { |i| ["#{i.send(label_attr)} [#{i.rank_name}]", i.send(value_attr)] }
    end

    #
    # Generate a result list for attributes that defined through a substitution array, or
    # are directly available in the database
    # The substitution array is similar to that provided by Dynamic Models for the definition of
    # a `data_attribute`, where each element of the array is substituted with the attribute value
    # if a matching named attribute exists, otherwise is included as a literal string.
    # The benefit of using this method over #list_for_complex_attributes is speed with large lists,
    # since we are able to identify just the attributes that are needed and they can be plucked directly
    # from a database query rather than instantiating every object
    # @param [ActiveRecord::Relation] reslist <description>
    # @return [Array]
    def list_for_defined_attributes(reslist, model)
      arr_label_attr, pluck_attrs, do_subs_label = pluck_attrs_for(label_attr, model)
      arr_value_attr, val_pluck_attrs, do_subs_value = pluck_attrs_for(value_attr, model)

      pluck_attrs += val_pluck_attrs
      pluck_attrs.uniq!
      sort_attr = pluck_attrs.first

      reslist_data = reslist.reorder('')
                            .order(sort_attr => :asc)
                            .pluck(*pluck_attrs)

      if pluck_attrs.one?
        # Entries with a single result will be returned, rather than pairs of [label, value], so we need to fix the data
        reslist_data = reslist_data.map { |r| [r, r] }
      end

      # Return the result if only simple attributes (not sustitution arrays) were requested
      return reslist_data unless do_subs_label || do_subs_value

      # A substitution array was provided, so go through and handle the substitution of each named attribute
      # Get the position of each attribute we expect to find in the results
      label_idx = arr_label_attr.map { |a| pluck_attrs.index(a) }
      value_idx = arr_value_attr.map { |a| pluck_attrs.index(a) }

      # Make the substitutions
      reslist_data.map do |r|
        res_label = label_idx.map.with_index { |a, i| a ? r[a] : arr_label_attr[i] }.join(' ')
        res_val = value_idx.map.with_index { |a, i| a ? r[a] : arr_value_attr[i] }.join(' ')
        [res_label, res_val]
      end
    end

    #
    # Find the required attributes to be plucked and consistently format attributes
    # @param [String | Array] attr
    # @param [UserBase] model
    # @return [Array{Array, Array, true}] -
    #   requested substitutions as an array,
    #   substitutions matching attributes to pluck,
    #   flag indicating that a substitution array was provided
    def pluck_attrs_for(attr, model)
      if attr.is_a?(Array)
        arr_attr = attr
        do_subs_label = true
        res = attr & model.attribute_names
      else
        res = arr_attr = [attr]
      end

      [arr_attr, res, do_subs_label]
    end

    #
    # Generate the result list for complex attributes (where the *data* attribute has been selected)
    # since it is likely that we can't retrieve this directly from the database since it is dynamically calculated.
    # The method #list_for_defined_attributes may be much faster than using named methods.
    # NOTE: we sort rather than SQL order, since data may be dynamically generated
    # and there may not actually be a data field for SQL to sort on
    # @param [ActiveRecord::Relation] reslist <description>
    # @return [Array]
    def list_for_complex_attributes(reslist)
      reslist.all
             .map { |i| [i.send(label_attr), i.send(value_attr)] }
             .sort { |x, y| x.first <=> y.first }
    end
  end
end
