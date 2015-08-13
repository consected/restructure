module Seeds
  module AccuracyScores

    def self.add_values values
      values.each do |v|
        res = AccuracyScore.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_accuracy_scores
      
      
      values = [
        {"name"=>"no match", "value"=>-1, "disabled"=>nil}, 
        {"name"=>"Minimal match", "value"=>2, "disabled"=>nil}, 
        {"name"=>"Match (6)", "value"=>6, "disabled"=>nil}, 
        {"name"=>"medium match", "value"=>7, "disabled"=>nil}, 
        {"name"=>"Reasonable match", "value"=>8, "disabled"=>nil}, 
        {"name"=>"Better Match", "value"=>9, "disabled"=>nil}, 
        {"name"=>"OK match", "value"=>10, "disabled"=>nil}, 
        {"name"=>"Good Match", "value"=>12, "disabled"=>nil},         
        {"name"=>"Current Player", "value"=>333, "disabled"=>nil}, 
        {"name"=>"Ineligible", "value"=>555, "disabled"=>nil}, 
        {"name"=>"Deceased", "value"=>777, "disabled"=>nil},         
        {"name"=>"Bad Match - requires follow up", "value"=>881, "disabled"=>nil}, 
        {"name"=>"Bad Match - must keep", "value"=>888, "disabled"=>nil}, 
        {"name"=>"Bad Match & Duplicate", "value"=>999, "disabled"=>nil}        
      ]
      
      add_values values
      
      Rails.logger.info "#{self.name} = #{AccuracyScore.all.length}"
    end
    
    
    def self.setup
      Rails.logger.info "Calling #{self}.setup"
      
      create_accuracy_scores
    end
  end
end
