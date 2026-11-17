# frozen_string_literal: true

# Shares activity-log definitions once per spec group.
module ActivityLogSetupSupport
  def with_activity_log_setup(
    gen_test_name: nil,
    process_name: nil,
    item_type: nil,
    rec_type: nil,
    player_contact_phones: false
  )
    before_all do
      SetupHelper.setup_al_player_contact_phones if player_contact_phones
      SetupHelper.setup_al_gen_tests(gen_test_name, process_name, item_type, rec_type:) if gen_test_name
    end
  end
end

RSpec.configure do |config|
  config.extend ActivityLogSetupSupport
end
