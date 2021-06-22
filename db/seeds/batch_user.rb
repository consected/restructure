# frozen_string_literal: true

module Seeds
  module BatchUser
    #
    # Set up a batch user if they don't yet exist
    def self.setup
      log "In #{self}.setup"
      return if User.batch_user

      User.create! email: Settings::BatchUserEmail, first_name: 'auto', last_name: 'batch user', current_admin: auto_admin
      log "Ran #{self}.setup"
    end
  end
end
