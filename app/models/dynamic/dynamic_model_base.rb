module Dynamic
  # Base class for all dynamic model implementations
  class DynamicModelBase < UserBase
    self.abstract_class = true

    include RankHandler
    include LimitedAccessControl
    include Dynamic::VersionedDefHandler
    include Dynamic::ImplementationHandler
  end
end
