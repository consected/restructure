module RecTypeHandler
  extend ActiveSupport::Concern


  included do

    self.valid_rec_types.each do |rt|
      is_rt = "is_#{rt}?".to_sym
      scope rt, ->{ where(rec_type: rt).order(rank: :desc)}
      before_validation :force_data_format
      if File.exist? "#{::Rails.root}/app/models/validates/#{rt}_validator.rb"
        validates :data, "validates/#{rt}": true, if: is_rt
      end
      validates :rec_type, presence: true

      Master.has_many "#{self.name.underscore}_#{rt}".pluralize.to_sym, -> { where(rec_type: rt).order(Master::RankNotNullClause)}, inverse_of: :master, class_name: self.name.to_s

    end

    validate :valid_data_format?

    self.valid_rec_types.each do |rt|
      # Setup the is_abc? methods such as is_phone?
      define_method("is_#{rt}?") do
        rec_type == rt.to_s
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


    # A function for formatting data attributes.
    # Uses a naming convention that allows it to be called by a child model, such as activity log,
    # without an instantiated model, to format phone numbers.
    def format_data value, rec_type=nil, options=nil
      formatter_do(rec_type, value, options)
    end
  end


  # This unfortunately may not always override the data setter to force the format of the
  # phone number. During initialization the rec_type may not be set yet, skipping the
  # formatting due to the condition is_phone? being false.
  # To cover this, we also override the rec_type attribute to call this.
  def data= value

    format_method = self.class.formatter_for(self.rec_type)
    if format_method
      res = self.class.formatter_do(self.rec_type, value)

      if res
        value = res
      else
        self.errors.add self.rec_type, "cannot be formatted. #{self.class.formatter_error_message(self.rec_type, value)}"
        self.mark_invalid = true
      end
    end

    super(value)
  end



  # When a new rec_type is set, force the data to be formatted appropriately
  def rec_type= new_rec_type
    self.class.formatter_do(new_rec_type, self.data)
    super(new_rec_type)
  end


  def force_data_format
    return "" if self.data.blank?
    d = self.class.format_data(self.data, self.rec_type)
    self.data = d || self.data
    true
  end

  def data_unformatted
    self.class.format_data(self.data, self.rec_type, format: :unformatted)
  end

  private

  def valid_data_format?
    return "" if self.data.blank?

    format_method = self.class.formatter_for(self.rec_type)
    if format_method
      res = self.class.formatter_do(self.rec_type, self.data)

      if res
        self.data = res
      else
        self.errors.add self.rec_type, "cannot be formatted. #{self.class.formatter_error_message(self.rec_type, self.data)}" if self.errors.empty?
        self.mark_invalid = true
      end
    else
      true
    end
  end


end
