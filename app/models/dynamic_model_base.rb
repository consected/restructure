# Base class for all dynamic model implementations
class DynamicModelBase < UserBase
  self.abstract_class = true

  include RankHandler
  include Formatter::Formatters
  include LimitedAccessControl
  include DynamicImplementationHandler
end
