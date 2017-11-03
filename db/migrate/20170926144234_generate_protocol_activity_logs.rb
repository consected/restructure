class GenerateProtocolActivityLogs < ActiveRecord::Migration


  ProtocolEventName = 'Phone Log'
  def self.up

    admin = Admin.where("disabled is null or disabled = false").first

    Protocol.enabled.each do |p|

      sp = p.sub_processes.create! name: ActivityLog.sub_process_name, current_admin: admin

      pe = sp.protocol_events.create! name: ProtocolEventName, current_admin: admin

      sp.update! disabled: true

    end

  end

  def self.down

execute <<EOF
    delete from protocol_event_history where name = '#{ProtocolEventName}';
    delete from protocol_events where name = '#{ProtocolEventName}';
    delete from sub_process_history where name = '#{ActivityLog.sub_process_name}';
    delete from sub_processes where name = '#{ActivityLog.sub_process_name}';

EOF

  end
end
