module Dynamic
  class ActivityLogBase < UserBase
    self.abstract_class = true
    include Dynamic::ImplementationHandler
  end
end
