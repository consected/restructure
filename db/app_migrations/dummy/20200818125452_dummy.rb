require 'active_record/migration/app_generator'
class Dummy < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dummy'
    self.table_name = 'dummy'
    self.fields = %i[]
    self.table_comment = ''
    self.fields_comments = {}
  end
end
