class ManualInvestigation < ActiveRecord::Base

  belongs_to :user
  belongs_to :master

end
