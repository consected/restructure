class AppConfiguration < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  validates :name, presence: true



  # Use `Configuration.value_for name` to get a cached configuration value

  # Allow the use of symbols to retrieve entries
  def self.value_for name
    if name.is_a? Symbol
      name = name.to_s.humanize.downcase
    end
    super name
  end

end
  
