class ExternalIdentifierBase < UserBase
  self.abstract_class = true
  include Formatter::Formatters
  include DynamicImplementationHandler
end
