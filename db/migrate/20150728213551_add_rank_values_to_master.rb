class AddRankValuesToMaster < ActiveRecord::Migration
  def change
    
    Master.all.each do |m|
      
      
      m.rank = m.accuracy_rank
      m.save
      
    end
    
  end
end
