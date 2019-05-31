class UserPreference

  def date_format
    'mm/dd/yyyy'
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

end
