module StringExtensions
  def hyphenate
    to_s.gsub(/_|\s/, '-')
  end

  def id_underscore
    to_s.downcase.gsub(/[^a-zA-Z0-9]/, '_')
  end

  # Underscore the string, replacing the generated namespace delimeter with
  # double underscore which is safe for HTML templates and URLs
  def ns_underscore
    to_s.underscore.gsub('/', '__')
  end

  # Hyphenate the string, replacing the generated namespace delimeter with
  # double underscore which is safe for HTML templates and URLs
  def ns_hyphenate
    to_s.ns_underscore.hyphenate
  end

  # Constantize the string (make it into a class), but
  # treat double underscores as a namespace delimiter.
  def ns_constantize
    to_s.gsub('__', '::').constantize
  end

  # Camelize the string, but
  # treat double underscores as a namespace delimiter.
  def ns_camelize
    to_s.gsub('__', '/').camelize
  end

  # Pathify the string, treating double underscores as a path separator
  def ns_pathify
    to_s.gsub('__', '/')
  end

  def true_if_1
    to_s == '1'
  end

  #
  # String to DateTime, ignoring non-date/time strings
  # @return [DateTime]
  def to_datetime_or_null
    to_datetime
  rescue ArgumentError
    nil
  end

  #
  # Alternative to titleize, to allow it to handle acronyms
  # We avoid using inflector, since it breaks classify and camelize, used
  # for class name handling across the app
  # @return [String]
  def captionize
    res = titleize
    Settings::CaptionAcronyms.each do |acronym|
      res = res.gsub(/(?<![\w\d])(#{acronym})(?![\w\d])/i, acronym)
    end
    res
  end
end

class String
  include StringExtensions
end

class Symbol
  include StringExtensions
end
