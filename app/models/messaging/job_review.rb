class Messaging::JobReview < Delayed::Job

  scope :index, -> { limit 10 }

  attr_accessor :disabled, :admin_id


end
