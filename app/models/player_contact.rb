class PlayerContact < UserBase
  include UserHandler
  include RankHandler

  before_validation :format_phone, if: :is_phone?
  validates :data, "validates/email": true, if: :is_email?
  validates :data, "validates/phone": true, if: :is_phone?
  validate :valid_format_phone?, if: :is_phone?
  validates :source, 'validates/source' => true, allow_blank: true
  validates :rank, presence: true
  scope :phone, ->{ where(rec_type: 'phone').order(rank: :desc)}
  scope :email, ->{ where(rec_type: 'email').order(rank: :desc)}

  # an informal key onto the table is the :data field
  def self.secondary_key
    :data
  end

  # This unfortunately may not always override the data setter to force the format of the
  # phone number. During initialization the rec_type may not be set yet, skipping the
  # formatting due to the condition is_phone? being false.
  # To cover this, we also override the rec_type attribute to call this.
  def data= value
    if is_phone?
      # Call the format function on the class to avoid recursive calls to set data
      res = self.class.format_phone(value, rec_type)
      if res
        value = res
      else
        self.errors.add "phone", "cannot be formatted. Check it is at least 10 digits and does not contain incorrect characters"
        self.mark_invalid = true
      end
    end
    super(value)
  end

  def rec_type= value
    if value.to_s == 'phone'
      format_phone
    end
    super(value)
  end

  # A function for formatting data attributes.
  # Uses a naming convention that allows it to be called by a child model, such as activity log,
  # without an instantiated model, to format phone numbers.
  def self.format_data value, rec_type='phone'
    res = format_phone(value, rec_type)
    return res || value
  end

  protected
    def is_email?
      rec_type == 'email'
    end
    def is_phone?
      rec_type == 'phone'
    end


  private

    def valid_format_phone?
      return "" if self.data.blank?
      res = self.class.format_phone(self.data, self.rec_type)
      if res
        self.data = res
      else
        self.errors.add "phone", "cannot be formatted. Check it is at least 10 digits and does not contain incorrect characters" if self.errors.empty?
        self.mark_invalid = true
      end
    end

    def format_phone
      return "" if self.data.blank?
      res = self.class.format_phone(self.data, self.rec_type)
      if res
        self.data = res
      end
      true
    end

    # Format a phone number to US format: "(aaa)bbb-cccc[ optional-freetext]"
    def self.format_phone data, rec_type='phone'
      if rec_type == 'phone' && !data.blank?
        res = '('
        num = 0
        data.chars.each do |s|

          if num == 10
            # we already have 10 digits, the remaining amount is plain text. Separate it with a space
            res << ' '
            res << s unless s.blank?
            num += 1
          elsif num > 10
            # handle the plain text
            res << s
            num += 1
          elsif s.to_i.to_s == s
            # the character is a digit
            res << s
            num += 1

            res << ')' if num == 3
            res << '-' if num == 6
          elsif !s.index(/[[[:punct:]]\s]/)
            # it wasn't whitespace or punctuation
            return nil
          end
          # we reject the items that aren't digits in while we are looking for the first 10
        end
        if num >= 10
          return res
        end
      end
      nil
    end
end
