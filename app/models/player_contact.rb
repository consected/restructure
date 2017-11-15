class PlayerContact < UserBase
  include UserHandler

  PrimaryRank = 10
  SecondaryRank = 5
  InactiveRank = 0

  before_validation :format_phone, if: :is_phone?
  validates :data, email: true, if: :is_email?
  validates :data, phone: true, if: :is_phone?
  validates :source, source: true, allow_blank: true
  validates :rank, presence: true
  after_save :handle_primary_status
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
        self.marked_invalid = true
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

    # A master record can only have one email and one phone with rank set to Primary
    # If a new player contact record is created or an existing record is updated with Primary rank
    # then update any other records for the master of that type (email or phone) to Secondary
    def handle_primary_status

      if self.rank.to_i == PrimaryRank
        logger.info "Player Contact rank set as primary in contact #{self.id} for type #{self.rec_type}.
                    Setting other player contacts for this master to secondary if they were primary and have the type #{self.rec_type}."

        self.master.player_contacts.where(rank: PrimaryRank, rec_type: self.rec_type).each do |a|
          logger.info "Player Contact #{a.id} has primary rank currently. Current ID is #{self.id}"
          if a.id != self.id
            logger.info "Player Contact #{a.id} has primary rank currently. Setting it to secondary"
            a.rank = 5
            a.save
            multiple_results << a
          end
        end
      end

    end

  private

    def format_phone
      res = self.class.format_phone(self.data, self.rec_type)
      if res
        self.data = res
      else
        self.mark_invalid = true
      end
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
