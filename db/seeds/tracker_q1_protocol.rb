module Seeds
  module TrackerQ1Protocol

    def self.add_values values, sub_process
      values.each do |v|
        res = sub_process.protocol_events.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_protocol_events
      
      protocol = Protocol.find_or_initialize_by(name: 'Q1')
      protocol.current_admin = auto_admin
      protocol.save!
      sp = protocol.sub_processes.find_or_initialize_by(name: 'Scantron')
      
      j =<<EOF
      [
{"name":"complete","disabled":false,"sub_process_id":1,"milestone":"complete","description":""},
{"name":"discontinue mailings","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"opt-out of mailings","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"pre-notification sent","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"questionnaire resent","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"questionnaire sent","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"received response","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"reminder sent","disabled":false,"sub_process_id":1,"milestone":null,"description":null},
{"name":"returned to sender","disabled":false,"sub_process_id":1,"milestone":"notify-user","description":"Mail returned to sender. The affected address must be edited to indicate a Bad Address. If alternative secondary addresses are available, consider marking one of these as 'primary'."},
{"name":"send thank you letter","disabled":false,"sub_process_id":1,"milestone":"notify-user, mailing","description":"Create a thank you letter for mailing. Update tracker for Q1 to Scantron Complete when done."},
{"name":"using new address","disabled":false,"sub_process_id":1,"milestone":null,"description":null}
]
EOF
      
      values = JSON.parse j
      puts "Create"
      add_values values, sp
      
      
      sp = protocol.sub_processes.find_or_initialize_by(name: 'REDCap')
      j =<<EOF
      [
{"name":"bounced email","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"discontinue emails","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"opt-out of email","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"received response","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"restart emails","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"send thank you email","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"started emails","disabled":false,"sub_process_id":2,"milestone":null,"description":null},
{"name":"using new email address","disabled":false,"sub_process_id":2,"milestone":null,"description":null}
]
      
EOF
      values = JSON.parse j
      add_values values, sp
      
      sp = protocol.sub_processes.find_or_initialize_by(name: 'Completion')

      j =<<EOF      
      [{"name":"complete","disabled":false,"sub_process_id":13,"milestone":null,"description":null},{"name":"opt-out of protocol","disabled":false,"sub_process_id":13,"milestone":null,"description":null}]
EOF
      
      values = JSON.parse j
      add_values values, sp
      
      
    end
    
    
    def self.setup
      Rails.logger.info "Calling #{self}.setup"
      
      create_protocol_events
    end
  end
end
