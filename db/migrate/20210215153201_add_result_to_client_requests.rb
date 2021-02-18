class AddResultToClientRequests < ActiveRecord::Migration[5.2]
  def change
    add_column 'ref_data.redcap_client_requests', :result, :jsonb
  end
end
