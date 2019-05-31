class UserPreference

  def attributes
    l = %i(date_format timezone pattern_for_date_format pattern_for_date_time_format pattern_for_time_format)
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
    "mm/dd/yyyy h:mm:sspm"
  end

  def time_format
    "h:mm:sspm"
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

end
