require 'active_record/migration/sql_helpers'
class CreateDatadicChoices < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    create_table 'ref_data.datadic_choices' do |t|
      t.string :source_name
      t.string :source_type
      t.string :form_name
      t.string :field_name
      t.string :value
      t.string :label
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.belongs_to :redcap_data_dictionary, foreign_key: true
      t.timestamps
    end

    create_table 'ref_data.datadic_choice_history' do |t|
      t.belongs_to :datadic_choice, foreign_key: true,
                                    index: { name: 'idx_history_on_datadic_choice_id' }

      t.string :source_name
      t.string :source_type
      t.string :form_name
      t.string :field_name
      t.string :value
      t.string :label
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.belongs_to :redcap_data_dictionary, foreign_key: true,
                                            index: { name: 'idx_dch_on_redcap_dd_id' }

      t.timestamps
    end

    create_general_admin_history_trigger('ref_data',
                                         :datadic_choices,
                                         %i[
                                           source_name
                                           source_type
                                           form_name
                                           field_name
                                           value
                                           label
                                           redcap_data_dictionary_id
                                         ])
  end
end
