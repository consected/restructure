class ProtocolOutcome < ActiveRecord::Base

  include AdminHandler
  include SelectorCache

  belongs_to :protocol
end
