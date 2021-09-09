module NfsStore
  module HasCurrentUser
    extend ActiveSupport::Concern

    class_methods do
      # Lookup the container being referenced and check it is accessible
      # Raises a not found exception if the container cannot be found with the specified ID
      # @param id [Integer] the ID of the container to be found
      # @param user [User] the user accessing the container
      # @return [NfsStore::Manage::Container] the container
      def open_container(id:, user:)
        id = if id.is_a? NfsStore::Manage::Container
               id.id
             else
               id.to_i
             end

        raise FsException::Action, 'container id must be set' unless id && id > 0
        raise FsException::Action, 'user must be set' unless user

        container = NfsStore::Manage::Container.find(id)
        container.current_user = user
        unless container.allows_current_user_access_to? :access
          raise FsException::NoAccess, 'user does not have access to this container'
        end

        container
      end
    end

    def current_user=(user)
      master.current_user = user
    end

    def current_user
      master.current_user
    end

    def master_id=(master_id)
      @master_id = master_id
    end

    def master_id
      container&.master_id
    end

    def master
      container&.master
    end
  end
end
