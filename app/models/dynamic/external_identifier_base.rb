module Dynamic
  class ExternalIdentifierBase < UserBase
    self.abstract_class = true
    include Dynamic::ImplementationHandler
  end
end
