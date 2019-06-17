module DynamicModelExtension
  module PlayerContactPhoneInfo

    extend ActiveSupport::Concern

    class_methods do

      # Get the player contact records that do not yet have phone info
      def incomplete_player_contacts limit: nil, ranks: [5, 10]
        PlayerContact.phone
          .joins('left outer join player_contact_phone_infos on player_contact_phone_infos.player_contact_id = player_contacts.id')
          .where('player_contact_phone_infos.id is null')
          .where(player_contacts: {rank: ranks})
          .limit(limit)
      end
    end

  end
end
