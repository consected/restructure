module DynamicModelHandler

  extend ActiveSupport::Concern


    class_methods do

      # Scope method to filter results based on whether they can be viewed according to user access controls
      # and default option config showable_if rules
      # @return [ActiveRecord::Relation] scope to provide rules filtered according to the calculated rules
      def filter_results

        sall = all
        return unless sall
        ex_ids = []
        sall.each do |r|
          ex_ids << r.id unless r.can_access?
        end

        if ex_ids.length == 0
          sall
        else
          where("#{self.table_name}.id not in (?)", ex_ids)
        end
      end

    end





  def can_edit?

    # This returns nil if there was no rule, true or false otherwise.
    # Therefore, for no rule (nil) return true
    res = calc_can :edit
    return true if res.nil?
    return if !res

    # Finally continue with the standard checks if none of the previous have failed
    super()
  end


  def can_access?
    res = calc_can :access
    return unless res

    # Finally continue with the standard checks if none of the previous have failed
    super()
  end

  # Calculate the can rules for the required type, based on user access controls and showable_if rules
  # @param type [Symbol] either :access or :edit for showable_if or editable_if
  def calc_can type
    # either use the editable_if configuration if there is one
    dopt = definition_default_options

    if type == :edit
      doptif = dopt.editable_if
    elsif type == :access
      doptif = dopt.showable_if
    end


    if doptif.is_a?(Hash) && doptif.first
      # Generate an old version of the object prior to changes
      old_obj = self.dup
      self.changes.each do |k,v|
        if k.to_s != 'user_id'
          old_obj.send("#{k}=", v.first)
        end
      end

      # Ensure the duplicate old_obj references the real master, ensuring current user can
      # be referenced correctly in conditional calculations
      old_obj.master = self.master

      if type == :edit
        res = !!dopt.calc_editable_if(old_obj)
      elsif type == :access
        res = !!dopt.calc_showable_if(old_obj)
      end
    end

    res

  end

  # Force the ability to add references even if can_edit? for the parent record returns false
  def can_add_reference?
    dopt = definition_default_options
    if dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first
      res = dopt.calc_add_reference_if(self)
      return !!res
    end
  end

end
