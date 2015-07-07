class AccuracyScore < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
  default_scope {order  :value}
end
