module ESignature
  module ESignatureHandler

    extend ActiveSupport::Concern

    included do
      before_action :prepare_create, only: [:create], if: -> {has_e_signature?}
      before_action :e_signature_password, only: [:create, :update], if: -> {has_e_signature?}

    end


    private

      def has_e_signature?
        object_instance.class.respond_to?(:has_e_signature?) && object_instance.class.has_e_signature?
      end

      def prepare_create use_object=nil
        oi = use_object || object_instance
        oi.current_user = current_user

        oi.prepare_activity_for_signature
      end


      # Evaluate the password for esignature activities
      def e_signature_password

        if secure_params[:e_signed_status] == ESignatureManager::SignNowStatus
          ufields = params[:user]
          return unless ufields.present?
          object_instance.e_signature_password = ufields[:password]
          object_instance.e_signature_otp_attempt = ufields[:otp_attempt]
        end

      end

  end
end
