module Users
  class ContactInfo < Admin::AdminBase


  include AdminHandler

  belongs_to :user

  before_validation :clean_sms_number
  validate :sms_number_valid
  validates :user_id, presence: true, uniqueness: true


  def clean_sms_number
    res = ""

    return unless self.sms_number && self.sms_number[0] == '+'
    return unless self.sms_number.length > 6

    res << '+'
    numbers = %w(0 1 2 3 4 5 6 7 8 9)

    self.sms_number.split('')[1..-1].each do |n|
      res << n if numbers.include?(n)
    end

    return unless res.length > 6
    self.sms_number = res
  end

  private

    def sms_number_valid
      unless Messaging::PhoneValidation.validate_sms_number_format self.sms_number, no_exception: true
        errors.add :sms_number, "is not valid. Ensure it has the correct format including +nnn country code"
        return false
      end
      true
    end

  end
end
