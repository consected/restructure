# frozen_string_literal: true

class AddAppTypeToProtocols < ActiveRecord::Migration[5.2]
  def change
    add_reference :protocols, :app_type, foreign_key: true

    Classification::Protocol.update_all(app_type_id: 1)
  end
end
