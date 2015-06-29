class ProtocolOutcome < ActiveRecord::Base

  include SelectorCache

  belongs_to :protocol
  belongs_to :admin
end
