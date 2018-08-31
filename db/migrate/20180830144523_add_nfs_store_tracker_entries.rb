class AddNfsStoreTrackerEntries < ActiveRecord::Migration
  def change

    admin = Admin.where(email: 'auto-admin@nodomain.com').first

    protocol = Classification::Protocol.active.where(name: 'Updates').first
    sp = protocol.sub_processes.where(name: 'record updates').first

    values = [
      {name: "created nfs store  manage  container", sub_process_id: sp.id},
      {name: "updated nfs store  manage  container", sub_process_id: sp.id},
      {name: "created nfs store  manage  stored file", sub_process_id: sp.id},
      {name: "updated nfs store  manage  stored file", sub_process_id: sp.id},
      {name: "created nfs store  manage  archived file", sub_process_id: sp.id},
      {name: "updated nfs store  manage  archived file", sub_process_id: sp.id}
    ]

    values.each do |cond|
      res = sp.protocol_events.where(cond).first
      unless res
        cond[:current_admin] = admin
        cond[:disabled] = false
        sp.protocol_events.create!(cond)
      end
    end

  end
end
