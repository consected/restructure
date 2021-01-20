# frozen_string_literal: true

require "#{::Rails.root}/spec/support/master_support"

module SeedSupport
  include MasterSupport

  def self.setup
    Rails.logger.info 'Starting seed setup'
    puts "#{Time.now} Starting SeedSupport setup"
    Seeds.setup
  end

  def setup
    puts "#{Time.now} Starting SeedSupport#setup"
    Seeds.setup
  end
end
