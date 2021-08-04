# frozen_string_literal: true

module EditFieldHelper
  #
  # Gets the #data for each record for a select on an association or class name
  #
  # @param [UserBase] form_object_instance the current instance for the form object
  # @param [String] assoc_or_class_name a master association name or an underscored class name to select from
  # @return [Array(String, Array(Array, Array))] a human name string and a list of data from the matched records
  #
  def list_record_data_for_select(form_object_instance, assoc_or_class_name)
    assoc_name = assoc_or_class_name.pluralize
    if Master.get_all_associations.include?(assoc_name)
      # We matched one of the possible classes an activity log be used with (really these are master associations)
      reslist = form_object_instance.master.send(assoc_name)
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
    end

    cl = reslist.first&.class
    if cl
      if cl.attribute_names.include?('rank')
        reslist = reslist.unscope(:order).order(rank: :desc)
        reslist_data = reslist.all.map { |i| ["#{i.data} [#{i.rank_name}]", i.data] }
      else
        # NOTE: we sort rather than SQL order, since data may be dynamically generated
        # and there may not actually be a data field for SQL to sort on
        reslist_data = reslist.all
                              .map { |i| [i.data, i.data] }
                              .sort { |x, y| x.first <=> y.first }
      end

      human_name = cl.human_name
    else
      logger.warn "Failed to find valid class name for #{assoc_or_class_name}"
    end

    # In case no results were found
    reslist_data ||= []

    [human_name, reslist_data]
  end
end
