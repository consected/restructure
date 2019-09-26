class ActivityLogBase < UserBase

  self.abstract_class = true
  include Formatter::Formatters


end
