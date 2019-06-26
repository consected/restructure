module AwsApi
  module SmsHandler

    extend ActiveSupport::Concern

    MobileTypes = ['MOBILE', 'PREPAID'].freeze
    LandlineTypes = ['LANDLINE'].freeze
    VoipTypes = ['VOIP'].freeze
    InvalidPhoneTypes = ['INVALID'].freeze
    OtherPhoneTypes = ['OTHER'].freeze

    class_methods do

      def sms_aws_region
        Messaging.sms_aws_region
      end

      def test_sms_number
        Messaging.test_sms_number
      end

      def sender_id
        Messaging.sender_id
      end

      def importance
        Messaging.importance
      end

    end


    def aws_logs_client
      return @aws_logs_client if @aws_logs_client
      @aws_logs_client = Aws::CloudWatchLogs::Client.new(region: self.class.sms_aws_region)
    end

    def aws_sns_client
      return @aws_sns_client if @aws_sns_client
      @aws_sns_client = Aws::SNS::Client.new(region: self.class.sms_aws_region)
    end

    def aws_pinpoint_client
      return @aws_pinpoint_client if @aws_pinpoint_client
      @aws_pinpoint_client = Aws::Pinpoint::Client.new(region: self.class.sms_aws_region)
    end

    def send_sms sms_number, generated_text, importance

      sms_number = self.class.test_sms_number unless Rails.env.production?

      aws_sns_client.publish(
        phone_number: sms_number,
        message: generated_text,
        message_attributes: {
          "AWS.SNS.SMS.SenderID" => {
            data_type: "String",
            string_value: self.class.sender_id
          },
          "AWS.SNS.SMS.SMSType" => {
            data_type: "String",
            string_value: importance
          }
        }
      )
    end



    def pp_phone_validate phone_number
      aws_pinpoint_client.phone_number_validate(
        number_validate_request: { # required
          # iso_country_code: "__string",
          phone_number: phone_number,
        }
      )
    end


  end
end
