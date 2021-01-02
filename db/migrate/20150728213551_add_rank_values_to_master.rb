class AddRankValuesToMaster < ActiveRecord::Migration
  def change
    Master.all.each do |m|
      pi = m.player_infos.first
      ar = if pi
             pi.accuracy_rank
           else
             -1000
           end

      m.rank = ar
      m.save
    end
  end
end
