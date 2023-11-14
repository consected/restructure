module TrackerSupport
  include MasterSupport

  def put_valid_attribs
    { notes: nil }
  end

  # TODO: consider creating an list_valid_attribs to be used in master_support.create_items(...)
  def list_valid_attribs_on_create
    res = []
    day = 0
    total_protocols = 5
    total_sub_processes = 3
    total_events = 3

    total_protocols.times do
      protocol = Classification::Protocol.create!(name: "Prot #{rand 100_000}",
                                                  current_admin: @admin)
      total_sub_processes.times do
        sub_process = protocol.sub_processes.create!(name: "Sub Process #{rand 100_000}",
                                                     disabled: false,
                                                     current_admin: @admin)
        total_events.times do
          event = sub_process.protocol_events.create!(name: "EV #{rand 100_000}",
                                                      current_admin: @admin)
          day -= 1
          event_date = DateTime.now + day.days
          res << {
            protocol_id: protocol.id,
            sub_process_id: sub_process.id,
            protocol_event_id: event.id,
            event_date: event_date,
            notes: 'some text ' * rand(100)
          }
        end
      end
    end

    res
  end

  def list_valid_attribs_in_progress; end

  def list_valid_attribs
    res = []

    day = 0

    5.times do
      protocol = Classification::Protocol.create! name: "Prot #{rand 100_000}", current_admin: @admin
      3.times do
        sp = protocol.sub_processes.create! name: "SP #{rand 100_000}", disabled: false, current_admin: @admin
        3.times do
          day += 1
          ev = sp.protocol_events.create! name: "EV #{rand 100_000}", current_admin: @admin
          event_date = DateTime.now + day.days
          # ev.name
          evid = ev.id
          sp1 = sp.id

          res << {
            protocol_id: protocol.id,
            sub_process_id: sp1,
            protocol_event_id: evid,
            event_date: event_date,
            notes: 'some text ' * rand(100)
          }
        end
      end
    end

    res
  end

  def list_invalid_attribs

    protocol = Classification::Protocol.create! name: "Prot #{rand 100_000}", current_admin: @admin
    sp = protocol.sub_processes.create! name: "SP #{rand 100_000}", disabled: false, current_admin: @admin
    ev = sp.protocol_events.create! name: "EV #{rand 100_000}", current_admin: @admin
    [
      {
        protocol_id: 1_000_000
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

  def create_item(att = nil, master = nil)
    att ||= valid_attribs
    master ||= create_master
    begin
      @tracker = master.trackers.create! att
    rescue StandardError => e
      puts "attr for failure: #{att}"
      raise e
    end
  end
end
