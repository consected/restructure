module DynamicModelHandler

  extend ActiveSupport::Concern


  def can_edit?

    # either use the editable_if configuration if there is one
    dopt = self.class.definition.default_options

    if dopt.editable_if.is_a?(Hash) && dopt.editable_if.first
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

      res = dopt.calc_editable_if(old_obj)
      return unless res
    end

    # Finally continue with the standard checks if none of the previous have failed
    super()
  end

  # Force the ability to add references even if can_edit? for the parent record returns false
  def can_add_reference?
    dopt = self.class.definition.default_options
    if dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first
      res = dopt.calc_add_reference_if(self)
      return !!res
    end
  end

end
