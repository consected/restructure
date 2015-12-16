class Scantron < ActiveRecord::Base
  
  include UserHandler
  include ExternalIdHandler
  
  validate :scantron_id_tests
  
  default_scope ->{}


  protected
    def scantron_id_tests
      
      if scantron_id_changed? || !persisted? 
        
        s = Scantron.find_by_scantron_id(self.scantron_id)
        if s           
          errors.add :scantron_id, "already exists in this master record" if s.master_id == self.master_id
          errors.add :scantron_id, "already exists in another master record (#{s.master.msid ? "MSID: #{s.master.msid}" : "master ID: #{s.master_id}"})" if s.master_id != self.master_id
        end
        
      end
      
    end
  
end
