module RecTypeHandler
  extend ActiveSupport::Concern


  included do

    self.valid_rec_types.each do |rt|
      is_rt = "is_#{rt}?".to_sym
      scope rt, ->{ where(rec_type: rt).order(rank: :desc)}
      validates :data, "validates/#{rt}": true, if: is_rt
      before_validation "format_#{rt}".to_sym, if: is_rt
      validate "valid_format_#{rt}?".to_sym, if: is_rt

    end

    self.valid_rec_types.each do |rt|
      # Setup the is_abc? methods such as is_phone?
      define_method("is_#{rt}?") do
        rec_type == rt.to_s
      end

      # Setup the format_abc methods such as format_phone
      define_method("format_#{rt}") do
        return "" if self.data.blank?
        res = self.class.format_data(self.data, rt)
        if res
          self.data = res
        end
        true
      end

      define_method("valid_format_#{rt}?") do
        return "" if self.data.blank?

        format_method = self.class.format_method_name(self.rec_type)
        if format_method
          res = self.class.send(format_method, self.data)

          if res
            self.data = res
          else
            self.errors.add rt, "cannot be formatted. #{self.class.format_error_message}" if self.errors.empty?
            self.mark_invalid = true
          end
        else
          true
        end
      end


    end


  end

  class_methods do

    # Validate rec_type
    # @param rec_type [String|Symbol]
    # @return [Boolean]
    def valid_rec_type? rec_type
      return nil unless rec_type
      self.valid_rec_types.include? rec_type.to_sym
    end

    def format_method_name rec_type
      raise FphsException.new "Unknown rec_type (#{rec_type}) for format_method_name" unless valid_rec_type?(rec_type)
      res = "format_#{rec_type}".to_sym
      respond_to?(res) ? res : nil
    end

    # A function for formatting data attributes.
    # Uses a naming convention that allows it to be called by a child model, such as activity log,
    # without an instantiated model, to format phone numbers.
    def format_data value, rec_type=nil
      format_method = format_method_name(rec_type)
      res = send(format_method, value) if format_method
      return res || value
    end
  end


  # This unfortunately may not always override the data setter to force the format of the
  # phone number. During initialization the rec_type may not be set yet, skipping the
  # formatting due to the condition is_phone? being false.
  # To cover this, we also override the rec_type attribute to call this.
  def data= value

    format_method = self.class.format_method_name(self.rec_type) if self.rec_type
    if format_method
      res = self.class.send(format_method, value)

      if res
        value = res
      else
        self.errors.add self.rec_type, "cannot be formatted. #{self.class.format_error_message}"
        self.mark_invalid = true
      end
    end

    super(value)
  end



  # When a new rec_type is set, force the data to be formatted appropriately
  def rec_type= new_rec_type
    format_method = self.class.format_method_name(new_rec_type) if new_rec_type
    res = send(format_method) if format_method

    super(new_rec_type)
  end


end
