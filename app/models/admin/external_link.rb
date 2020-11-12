class Admin::ExternalLink < ActiveRecord::Base

  self.table_name = 'external_links'

  include AdminHandler
  include SelectorCache

  validates :name, presence: true
end
