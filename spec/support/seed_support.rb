require "#{::Rails.root}/spec/support/master_support"

module SeedSupport
  include MasterSupport

  def self.setup
    Rails.logger.info "NOT Starting seed setup"
    # Seeds.setup
  end

  def setup

    # Seeds.setup
  end


end
