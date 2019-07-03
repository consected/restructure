module DynamicModelExtension
  module ZeusBulkMessageStatus

    extend ActiveSupport::Concern

    ValidStatuses = [:success, :failure]
    
    included do
      belongs_to :zeus_bulk_message_recipients

      validates :zeus_bulk_message_recipient_id, presence: true
    end

    class_methods do

      def extension_setup
        include AwsApi::SmsHandler
      end

      # Get
      def incomplete_recipients
        ZeusBulkMessageRecipient
          .select('zeus_bulk_message_recipients.*')
          .joins('LEFT OUTER JOIN zeus_bulk_message_statuses ON zeus_bulk_message_statuses.zeus_bulk_message_recipient_id = zeus_bulk_message_recipients.id')
          .where("zeus_bulk_message_recipients.response is not null and zeus_bulk_message_recipients.disabled = false")
          .where(zeus_bulk_message_statuses: {id: nil})
          .order('zeus_bulk_message_recipients.created_at asc')
      end

      # Get the timestamp on the earliest recipient record where a message was sent (response is not null)
      # and a matching delivery status record is not found
      def earliest_incomplete_timestamp
        res = incomplete_recipients.first

        return unless res

        res.created_at
      end

      def date_to_millisec d
        (d.to_f * 1000).to_i
      end

      # Find matching recipient by the message id.
      # @param state [Symbol] defaults to show only those records that are not complete and have a don't have a status, otherwise set state to anything else to get both complete and incomplete records
      def find_matching_recipient_by_message_id message_id, state: :incomplete
        restext = "[{\"aws_sns_sms_message_id\":\"#{message_id}\"}]"

        if state == :incomplete
          res = incomplete_recipients
        else
          res = ZeusBulkMessageRecipient
        end
        res = res.where(response: restext)
        return res.first
      end

      # Add status records based on the log entries
      # @param limit [Integer] limits the total number of records processed (for testing or to reduce job time)
      def add_status_from_log limit: nil

        bms = new

        from_ts = earliest_incomplete_timestamp

        set_recips = []
        limit ||= 10000


        [:success, :failure].each do |status|
          total = 0
          # Get the delivery responses for the current status, starting at the earliest timestamp we haven't handled yet
          responses = bms.delivery_responses status, limit: limit, start_timestamp: from_ts
          got_responses = responses && (responses[:events].length > 0)
          while got_responses
            responses[:events].each do |r|
              recip = find_matching_recipient_by_message_id r[:message_id]
              if recip
                recip.master.current_user = recip.user
                set_recips << create!(
                  status: r[:status],
                  status_reason: r[:status_reason],
                  zeus_bulk_message_recipient_id: recip.id,
                  master: recip.master,
                  res_timestamp: r[:timestamp],
                  message_id: r[:message_id]
                )
                total += 1
              else
                puts "Recipient not found: #{r[:message_id]}"
              end
            end
            break if total >= limit || !responses[:more_results]
            responses = bms.delivery_responses status, limit: limit
            got_responses = responses && (responses[:events].length > 0)
          end
        end

        set_recips
      end


    end





    # Get a set of log_group_names strings for the sns sms deliveries
    # @return [Hash] keyed with :failure and :success
    def aws_log_groups

      return @aws_log_groups if @aws_log_groups

      res = aws_logs_client.describe_log_groups(
        log_group_name_prefix: "sns"
      )

      groups = {}

      groups[:failure] = res.log_groups.select {|g| g.log_group_name.end_with? '/DirectPublishToPhoneNumber/Failure'}.first&.log_group_name
      groups[:success] = res.log_groups.select {|g| g.log_group_name.end_with? '/DirectPublishToPhoneNumber'}.first&.log_group_name

      @aws_log_groups = groups
    end



    # Get the delivery responses for a specific status (:success or :failure). If there are more results than we can get in one request,
    # the more_results Boolean will be true
    # The events are sort chronologically
    # #events returns the parsed message
    # #raw_events returns the raw CloudWatch log event data
    # @param status [Symbol]
    # @param next_page [Boolean] get the next page of results (default if a request has already returned a result), or if false start at the beginning
    # @param start_timestamp [Integer|Time] find responses from this timestamp (setting this assumes next_page=false). Integer time in milliseconds or Time
    # @param limit [nil|Integer] if set, this limits the number of records returned
    # @return [Hash] { events: Array, raw_events, more_results: Boolean }


    # Success events are like:
    # {
    #     notification: {
    #         "messageId": "34d9b400-c6dd-5444-820d-fbeb0f1f54cf",
    #         "timestamp": "2016-06-28 00:40:34.558"
    #     },
    #     "delivery": {
    #         "phoneCarrier": "My Phone Carrier",
    #         "mnc": 270,
    #         "destination": "+1XXX5550100”,
    #         "priceInUSD": 0.00645,
    #         "smsType": "Transactional",
    #         "mcc": 310,
    #         "providerResponse": "Message has been accepted by phone carrier",
    #         "dwellTimeMs": 599,
    #         "dwellTimeMsUntilDeviceAck": 1344
    #     },
    #     "status": "SUCCESS"
    # }

    # Failure events are like:
    # {
    #     "notification": {
    #         "messageId": "1077257a-92f3-5ca3-bc97-6a915b310625",
    #         "timestamp": "2016-06-28 00:40:34.559"
    #     },
    #     "delivery": {
    #         "mnc": 0,
    #         "destination": "+1XXX5550100”,
    #         "priceInUSD": 0.00645,
    #         "smsType": "Transactional",
    #         "mcc": 0,
    #         "providerResponse": "Unknown error attempting to reach phone",
    #         "dwellTimeMs": 1420,
    #         "dwellTimeMsUntilDeviceAck": 1692
    #     },
    #     "status": "FAILURE"
    # }

    # Possible failure reasons include:
        # Blocked as spam by phone carrier
        # Destination is blacklisted
        # Invalid phone number
        # Message body is invalid
        # Phone carrier has blocked this message
        # Phone carrier is currently unreachable/unavailable
        # Phone has blocked SMS
        # Phone is blacklisted
        # Phone is currently unreachable/unavailable
        # Phone number is opted out
        # This delivery would exceed max price
        # Unknown error attempting to reach phone


    def delivery_responses status, next_page: true, start_timestamp: nil, limit: nil

      raise FphsException.new "Invalid bulk message log status: #{status}" unless ValidStatuses.include? status

      max_timestamp = nil
      next_page = false if start_timestamp || status !=  @current_status
      @next_token = nil unless next_page

      start_timestamp = self.class.date_to_millisec(start_timestamp) unless start_timestamp.nil? || start_timestamp.is_a?(Integer)

      @current_status = status

      @events = []
      @raw_events = []

      if next_page && !@next_token
        # We erroneously asked for a next page even though there isn't one
        # This possibly means the caller is not checking the more_results value
        # and risks looping forever
        return
      end

      conds = {
          log_group_name: aws_log_groups[status],
          next_token: @next_token,
          limit: limit,
          start_time: start_timestamp
      }

      res = aws_logs_client.filter_log_events(conds)

      @raw_events = res.events
      @next_token = res.next_token

      if @raw_events.length > 0
        max_timestamp = @raw_events.last.timestamp
        @raw_events.sort_by! {|e| e.timestamp}

        @events = @raw_events.map {|re|
          begin
            reh = JSON.parse(re.message).deep_symbolize_keys
            reh[:status] = reh[:status].downcase.to_sym
            reh[:message_id] = reh[:notification][:messageId]
            reh[:status_reason] = reh[:delivery][:providerResponse]
          rescue => e
            reh = {
              status: :error,
              error_reason: "Failed to handle delivery status: #{e}",
              original_message: re&.message
            }
          end
          reh
        }
      end

      {
        raw_events: @raw_events,
        events: @events,
        more_results: !!@next_token,
        max_timestamp: max_timestamp
      }

    end



  end
end
