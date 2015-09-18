module TrackerSupport
  include MasterSupport
  
  def put_valid_attribs
    
    {notes: nil}
  end
  
  
  def list_valid_attribs
    res = []
    
    
    
    (1..5).each do |l|
      protocol = Protocol.create! name: "Prot #{rand 100000}", current_admin: @admin
      (1..3).each do |s|
        sp = protocol.sub_processes.create! name: "SP #{rand 100000}", disabled: false, current_admin: @admin      
        
        (1..3).each do |e|
          ev = sp.protocol_events.create! name: "EV #{rand 100000}", current_admin: @admin      
          event_date = DateTime.now
          evn = ev.name
          evid = ev.id
          sp1 = sp.id
           
          # remove some events and sub_processes
#          if e.even?
#            ev = nil
#            evn = nil
#            evid = nil
#            event_date = nil
#            if s.even?
#              sp1 = nil
#                                         
#            end
#          end
          
          res << {
            protocol_id: protocol.id,
            sub_process_id: sp1,
            protocol_event_id: evid,
            event_date: event_date,
            notes: "some text " * rand(100) 
          }
                    
        end
      end
    end
    
    res
  end
  
  def list_invalid_attribs
    
    protocol = Protocol.create! name: "Prot #{rand 100000}", current_admin: @admin
    sp = protocol.sub_processes.create! name: "SP #{rand 100000}", disabled: false, current_admin: @admin   
    ev = sp.protocol_events.create! name: "EV #{rand 100000}", current_admin: @admin      
    
    [
      {
        protocol_id: 1000000
      },
      {
        protocol_id: nil
      },
      {
        sub_process_id: nil,
        protocol_id: protocol.id,        
        protocol_event_id: ev.id
      },
      {
        event_date: nil,
        protocol_id: protocol.id,
        sub_process_id: sp.id,
        protocol_event_id: ev.id
        
      }
    ]
  end
  
  def new_attribs
    @new_attribs = {
      notes: nil
    }
  end
  
  
  
  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    begin
      @tracker = master.trackers.create! att
    rescue => e
      puts "attr for failure: #{att}"
      raise e
    end
  end
  
end
