module AwsApi
  module SmsHandler
    extend ActiveSupport::Concern

    MobileTypes = ['MOBILE', 'PREPAID'].freeze
    LandlineTypes = ['LANDLINE'].freeze
    VoipTypes = ['VOIP'].freeze
    InvalidPhoneTypes = ['INVALID'].freeze
    OtherPhoneTypes = ['OTHER'].freeze
    ValidImportances = ['Promotional', 'Transactional'].freeze

    class_methods do
      def sms_aws_region
        AwsApiSetup.sms_aws_region
      end

      def test_sms_number
        AwsApiSetup.test_sms_number
      end

      def sender_id
        AwsApiSetup.sender_id
      end

      def importance
        AwsApiSetup.importance
      end
    end

    #
    # Direct access to the AWS CloudWatch Logs client in the region
    # configured for SMS notifications
    # @return [Aws::CloudWatchLogs::Client]
    def aws_logs_client
      return @aws_logs_client if @aws_logs_client

      @aws_logs_client = Aws::CloudWatchLogs::Client.new(region: self.class.sms_aws_region)
    end

    #
    # SNS client for sending SMS messages
    # Not expected to be used directly, but through helper instance methods
    # @return [Aws::SNS::Client] <description>
    def aws_sns_client
      return @aws_sns_client if @aws_sns_client

      @aws_sns_client = Aws::SNS::Client.new(region: self.class.sms_aws_region)
    end

    #
    # Pinpoint Client for validation and identification of phone numbers
    # Not expected to be used directly, but through helper instance methods
    # @return [Aws::Pinpoint::Client]
    def aws_pinpoint_client
      return @aws_pinpoint_client if @aws_pinpoint_client

      @aws_pinpoint_client = Aws::Pinpoint::Client.new(region: self.class.sms_aws_region)
    end

    #
    # Call AWS to send an SMS immediately
    # @param [String] sms_number
    # @param [String] msg_text
    # @param [String] importance - one of ValidImportances
    # @return [Aws::SNS::Types::PublishResponse] Structure containing attribute:
    #   #message_id (String)
    def send_sms(sms_number, msg_text, importance)
      # Use a fixed test number for dev and test (non production) environments
      sms_number = self.class.test_sms_number unless Rails.env.production?

      raise FphsException, "Invalid SMS importance: #{importance}" unless valid_importance?(importance)

      aws_sns_client.publish(
        phone_number: sms_number,
        message: msg_text,
        message_attributes: {
          'AWS.SNS.SMS.SenderID' => {
            data_type: 'String',
            string_value: self.class.sender_id
          },
          'AWS.SNS.SMS.SMSType' => {
            data_type: 'String',
            string_value: importance
          }
        }
      )
    end

    #
    # Check the provided *importance* is valid
    # @param [String] importance
    # @return [Boolean]
    def valid_importance?(importance)
      importance&.in? ValidImportances
    end

    #
    # Get a page of the list of phone numbers opted out from AWS
    # @param [String | nil] next_token - a token identifying the next page to retrieve
    # @return [Aws::SNS::Types::ListPhoneNumbersOptedOutResponse] - a Struct returning:
    #   #phone_numbers (Array)
    #   #next_token (String)
    def list_sms_opt_outs(next_token: nil)
      cond = {}
      cond[:next_token] = next_token if next_token
      aws_sns_client.list_phone_numbers_opted_out cond
    end

    #
    # Validate a phone number, optionally in a specific country
    # @param [String] phone_number
    # @param [String] iso_country_code (optional) 2 letter ISO country code
    # @return [Aws::Pinpoint::Types::PhoneNumberValidateResponse] results in a structure
    #   containing validation information in an attribute #number_validate_response
    #   or #number_validate_response = nil if invalid
    def pp_phone_validate(phone_number, iso_country_code = nil)
      request = {
        phone_number: phone_number
      }
      request[:iso_country_code] = iso_country_code if iso_country_code

      aws_pinpoint_client.phone_number_validate(
        number_validate_request: request
      )
    end
  end
end
