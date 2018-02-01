# Create tracker items for a master

To test performance it may be useful to create multiple tracker items for a master record

Run the following in `rails console`


    m = Master.find(some_id)


    def create_trackers_for master
       Protocol.active.each do |p|    
         p.sub_processes.active.each do |sp|
           active_sp = sp.protocol_events.active
           if active_sp.length > 0
             active_sp.each do |pe|
               master.trackers.create(protocol_id: p.id, sub_process_id: sp.id, protocol_event_id: pe.id, event_date: DateTime.now)
             end
           else
             master.trackers.create(protocol_id: p.id, sub_process_id: sp.id, event_date: DateTime.now)
           end
         end
      end
    end


    m.current_user = User.active.first
    create_trackers_for m
