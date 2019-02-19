module ESignature
  module ESignatureHandler

    extend ActiveSupport::Concern

    included do
      before_action :prepare_create, only: [:create]
      before_action :e_signature_password, only: [:create, :update]

    end


    private

      def prepare_create use_object=nil
        oi = use_object || object_instance
        oi.current_user = current_user

        oi.prepare_activity_for_signature
      end


      # Evaluate the password for esignature activities
      def e_signature_password
        if object_instance.class.has_e_signature?
          if params[:e_signed_status] == ESignatureManager::SignNowStatus
            ufields = params[:user]
            return unless ufields
            object_instance.e_signature_password = ufields[:password]
          end
        end
      end

  end
end
