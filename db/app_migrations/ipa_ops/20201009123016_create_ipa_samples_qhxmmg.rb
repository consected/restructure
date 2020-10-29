require 'active_record/migration/app_generator'
class CreateIpaSamplesQhxmmg < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_samples'
    self.fields = %i[ipa_sample_ext_id select_test_type]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false

    create_external_identifier_tables :ipa_sample_ext_id, :bigint
    create_external_identifier_trigger :ipa_sample_ext_id
  end
end
