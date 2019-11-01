module DynamicModelExtension
  module PlayerContactPhoneInfo

    extend ActiveSupport::Concern

    class_methods do

      def extension_setup
        PlayerContact.has_one :player_contact_phone_info, class_name: 'DynamicModel::PlayerContactPhoneInfo'
        include AwsApi::SmsHandler
      end

      # Get the player contact records that do not yet have phone info
      def incomplete_player_contacts conditions: {}, limit: nil

        conditions[:rank] ||= [5, 10]

        PlayerContact.phone
          .joins('left outer join player_contact_phone_infos on player_contact_phone_infos.player_contact_id = player_contacts.id')
          .where('player_contact_phone_infos.id is null')
          .where(player_contacts: conditions)
          .limit(limit)
      end

      def validate_incomplete conditions: {}, limit: nil, user: nil, def_country_code: 1
        # Get all the IDs to allow an upsert to be quickly calculated without having to return to the database
        all_ids = all.pluck(:player_contact_id)

        inc = incomplete_player_contacts(conditions: conditions, limit: limit)

        pv = Messaging::PhoneValidation.new
        inc.each do |pc|
          pn = Formatter::Phone.format pc.data, format: :unformatted, default_country_code: def_country_code
          res = pv.validate pn

          res.each do |k, v|
            res[k] = v.downcase if res[k].is_a? String
          end

          # Upsert the result depending on if the incomplete player contacts already has this player contact
          if all_ids.include? pc.id
            update! res
          else

            user ||= pc.user
            master = pc.master
            master.current_user = user
            res[:player_contact_id] = pc.id
            master.dynamic_model__player_contact_phone_infos.create! res
          end
        end

      end

      def update_opt_outs max_iters=1000

        nt = nil
        total_opt_outs = 0

        pcpi_inst = DynamicModel::PlayerContactPhoneInfo.new

        batch_user = User.use_batch_user(Settings.bulk_msg_app) if Settings.bulk_msg_app


        (0..max_iters).each do |i|
          res = pcpi_inst.list_sms_opt_outs next_token: nt
          nt = res.next_token

          res.phone_numbers.each do |pn|

            pcpi = DynamicModel::PlayerContactPhoneInfo.where(cleansed_phone_number_e164: pn).first

            if pcpi
              unless pcpi.opted_out_at
                # Not opted-out yet
                pcpi.opted_out_at = DateTime.now
                pcpi.current_user = batch_user || pcpi.user  # the latter user is only likely to be needed in test 
                ures = pcpi.save

       	       	Rails.logger.warn "Could not update player contact phone info record #{pcpi.id}: #{pcpi.errors.first}" unless ures

              end
              total_opt_outs += 1
            else
              Rails.logger.warn "SMS opt out received from a phone that is not a player contact phone info record: #{pn}"
            end

          end

          break unless nt

        end

        total_opt_outs

      end



    end

  end
end
