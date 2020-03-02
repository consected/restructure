class ApplicationJob < ActiveJob::Base
  attr_accessor :provider_job

  def log txt
    puts txt unless Rails.env.test?
  end

end
