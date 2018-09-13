module NfsStore
  module InNfsStoreContainer
    extend ActiveSupport::Concern

    included do
      before_action :find_container
    end

    private

      def find_container
        if action_name.in? ['create', 'update']
          cid = secure_params[:container_id]
        else
          cid = params[:id]
        end
        @container = Browse.open_container id: cid, user: current_user
      end

  end
end
