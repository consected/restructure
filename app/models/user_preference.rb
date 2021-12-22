class UserPreference
  def initialize(user: nil)
    @belongs_to_user = user
  end

  # Fake the association
  def user_id
    @belongs_to_user&.id
  end

  # Fake the ID
  def id
    @belongs_to_user&.id
  end

  def created_at
    @belongs_to_user&.created_at
  end

  def updated_at
    @belongs_to_user&.updated_at
  end

  # Fake attribute names
  def self.attribute_names
    %w[id user_id date_format timezone pattern_for_date_format pattern_for_date_time_format pattern_for_time_format
       created_at updated_at]
  end

  def attributes
    l = self.class.attribute_names
    res = {}
    l.each do |i|
      res[i.to_s] = send(i)
    end
    res
  end

  def date_format
    'mm/dd/yyyy'
  end

  def date_time_format
    'mm/dd/yyyy h:mm:sspm'
  end

  def time_format
    'h:mm:sspm'
  end

  def timezone
    'Eastern Time (US & Canada)'
  end

  def pattern_for_date_format
    '%m/%d/%Y'
  end

  def pattern_for_date_time_format
    '%m/%d/%Y %l:%M%p'
  end

  def pattern_for_time_format
    '%l:%M%p'
  end

  def self.default_pattern_for_date_format
    '%m/%d/%Y'
  end

  def self.default_pattern_for_date_time_format
    '%m/%d/%Y %l:%M%p'
  end

  def self.default_pattern_for_time_format
    '%l:%M%p'
  end

  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end

  # Fake JSON production - scrap this in real life
  def as_json(options = nil)
    attributes.as_json(options)
  end

  # Dummy
  def current_user=(curr); end
end
