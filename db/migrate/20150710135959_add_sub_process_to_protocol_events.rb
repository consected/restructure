class AddSubProcessToProtocolEvents < ActiveRecord::Migration
  def change
    add_belongs_to :protocol_events, :sub_process, index: true, foreign_key: true
    remove_belongs_to :protocol_events, :protocol, index: true, foreign_key: true
  end
end
