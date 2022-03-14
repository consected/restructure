# frozen_string_literal: true

module DynamicModelExtension
  #
  # Extensions to a femfl contact phone to handle common functionality
  # for phone numbers, including validation and opt outs
  module FemflContactPhoneInfo
    extend ActiveSupport::Concern

    class_methods do
      def extension_setup
        FemflContact.has_one :femfl_contact_phone_info, class_name: 'DynamicModel::FemflContactPhoneInfo'
        include AwsApi::SmsHandler
      end

      #
      # Get the femfl contact records that do not yet have phone info
      # By default only primary and secondary rank contacts are used, unless
      # conditions[:rank] is set to a not-nil value
      # @param [Hash] conditions - additional conditions
      # @param [Integer | nil] limit - number of records
      # @return [ActiveRecord::Relation]
      def incomplete_femfl_contacts(conditions: {}, limit: nil)
        conditions[:rank] ||= [5, 10]

        FemflContact.phone
                    .joins('left outer join femfl_contact_phone_infos ' \
                            'on femfl_contact_phone_infos.femfl_contact_id = femfl_contacts.id')
                    .where('femfl_contact_phone_infos.id is null')
                    .where(femfl_contacts: conditions)
                    .where.not(femfl_contacts: { master_id: nil })
                    .limit(limit)
                    .reorder('')
                    .order(id: :asc)
      end

      #
      # Validate incomplete femfl contact records - those without corresponding
      # femfl_contact_phone_infos records.
      # @param [Hash] conditions - additional conditions
      # @param [Integer | nil] limit - number of records
      # @param [User] user - current user to create new validation records
      # @param [String] def_country_code - country code number as a string
      # @return [Integer] - number of items processed
      def validate_incomplete(conditions: {}, limit: nil, user: nil, def_country_code: 1)
        rescount = 0

        inc = incomplete_femfl_contacts(conditions: conditions, limit: limit)

        pv = Messaging::PhoneValidation.new
        inc.each do |pc|
          pn = Formatter::Phone.format pc.data, format: :unformatted, default_country_code: def_country_code
          res = pv.validate pn

          res.each do |k, v|
            res[k] = v.downcase if res[k].is_a? String
          end

          # Upsert the result depending on if the incomplete femfl contacts already has this femfl contact
          already_exists = pc.femfl_contact_phone_info
          if already_exists
            begin
              already_exists.current_user = batch_user || already_exists.user
              already_exists.update! res
            rescue StandardError => e
              Rails.logger.warn "Failed to update femfl_contact_phone_info (#{pc.id}) with #{res}\n#{e}"
              raise e if e.to_s.start_with?('This item is not editable')
            end
          else
            begin
              user ||= pc.user
              master = pc.master
              master.current_user = user
              res[:femfl_contact_id] = pc.id
              master.dynamic_model__femfl_contact_phone_infos.create! res
            rescue StandardError => e
              Rails.logger.warn "Failed to create femfl_contact_phone_info with #{res}\n#{e}"
              raise e if e.to_s == 'This item can not be created (Femfl Contact Phone Info)'
            end
          end
          rescount += 1
        end

        rescount
      end

      #
      # Update femfl contacts phone info to capture text message opt outs (SMS 'STOP')
      # From the AWS SNS API.
      # @param [Integer] max_iters - max iterations of the opt out API - default 1000
      # @return [Integer] - total number of opt outs
      def update_opt_outs(max_iters = 1000)
        nt = nil
        total_opt_outs = 0

        pcpi_inst = DynamicModel::FemflContactPhoneInfo.new

        batch_user = User.use_batch_user(Settings.bulk_msg_app) if Settings.bulk_msg_app

        (0..max_iters).each do |_i|
          res = pcpi_inst.list_sms_opt_outs next_token: nt
          nt = res.next_token

          res.phone_numbers.each do |pn|
            pcpi = DynamicModel::FemflContactPhoneInfo.where(cleansed_phone_number_e164: pn).first

            unless pcpi
              Rails.logger.warn 'SMS opt out received from a phone that ' \
                                "is not a femfl contact phone info record: #{pn}"
              next
            end

            unless pcpi.opted_out_at
              # Not opted-out yet
              begin
                pcpi.opted_out_at = DateTime.now
                pcpi.current_user = batch_user || pcpi.user  # the latter user is only likely to be needed in test
                pcpi.save!
              rescue StandardError => e
                Rails.logger.warn "Could not update femfl contact phone info record: #{pcpi.id}\n#{e}"
                raise e if e.to_s.start_with?('This item is not editable')
              end
            end
            total_opt_outs += 1
          end

          break unless nt
        end

        total_opt_outs
      end
    end
  end
end
