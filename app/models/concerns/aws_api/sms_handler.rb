module AwsApi
  module SmsHandler

    extend ActiveSupport::Concern


    class_methods do

      def sms_aws_region=r
        @sms_aws_region = r
      end

      def sms_aws_region
        @sms_aws_region
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


    def send_sms sms_number, generated_text, importance

      sms_number = '+16177942330' unless Rails.env.production?

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

  end
end
