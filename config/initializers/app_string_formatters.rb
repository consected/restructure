module StringExtensions
  def hyphenate
    self.to_s.gsub(/_|\s/,'-')
  end

  def id_underscore
    self.to_s.downcase.gsub(/[^a-zA-Z0-9]/,'_')
  end

  # Underscore the string, replacing the generated namespace delimeter with
  # double underscore which is safe for HTML templates and URLs
  def ns_underscore
    self.to_s.underscore.gsub('/', '__')
  end

  # Hyphenate the string, replacing the generated namespace delimeter with
  # double underscore which is safe for HTML templates and URLs
  def ns_hyphenate
    self.to_s.ns_underscore.hyphenate
  end

  # Constantize the string (make it into a class), but
  # treat double underscores as a namespace delimiter.
  def ns_constantize
    self.to_s.gsub('__', '::').constantize
  end

  # Camelize the string, but
  # treat double underscores as a namespace delimiter.
  def ns_camelize
    self.to_s.gsub('__', '/').camelize
  end

  # Pathify the string, treating double underscores as a path separator
  def ns_pathify
    self.to_s.gsub('__', '/')
  end

end

class String

  include StringExtensions

end

class Symbol

  include StringExtensions

end
