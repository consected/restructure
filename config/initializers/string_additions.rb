class String
  def hyphenate
    self.gsub('_','-')
  end
  
  def id_underscore
    self.downcase.gsub(/[^a-zA-Z0-9]/,'_')
  end
end
