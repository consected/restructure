module Dynamic
  class ActivityLogBase < UserBase
    self.abstract_class = true
    include Formatter::Formatters
    include Dynamic::ImplementationHandler
  end
end
