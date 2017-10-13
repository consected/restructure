class String
  def hyphenate
    self.gsub('_','-')
  end

  def id_underscore
    self.downcase.gsub(/[^a-zA-Z0-9]/,'_')
  end

  # Underscore the string, replacing the generated namespace delimeter with
  # double underscore which is safe for HTML templates and URLs
  def ns_underscore
    self.underscore.gsub('/', '__')
  end

  # Constantize the string (make it into a class), but
  # treat double underscores as a namespace delimiter.
  def ns_constantize
    self.gsub('__', '::').constantize
  end

  # Camelize the string, but
  # treat double underscores as a namespace delimiter.
  def ns_camelize
    self.gsub('__', '/').camelize
  end

end
