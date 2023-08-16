module NfsStore
  module HasCurrentUser
    extend ActiveSupport::Concern

    class_methods do
      # Lookup the container being referenced and check it is accessible
      # Raises a not found exception if the container cannot be found with the specified ID.
      # The user access checks:
      # - a current user is set
      # - access granted to nfs_store__manage__containers
      # - if the user has access to the associated master record through limit and limited_if_none type access
      # @param id [Integer] the ID of the container to be found
      # @param user [User] the user accessing the container
      # @return [NfsStore::Manage::Container] the container
      def open_container(id:, user:)
        cid = if id.is_a? NfsStore::Manage::Container
                container = id
                id.id
              else
                id.to_i
              end

        raise FsException::Action, 'container id must be set' unless cid && cid > 0
        raise FsException::Action, 'user must be set' unless user

        container ||= NfsStore::Manage::Container.find(cid)
        container.current_user = user
        unless container.allows_current_user_access_to? :access
          cp = container.parent_item || container.find_creator_parent_item
          cpm = cp&.master&.id if cp.respond_to?(:master)

          raise FsException::NoAccess,
                'user does not have access to this container ' \
                "(master #{container.master&.id} - parent #{cp.class} id: #{cp&.id} master: #{cpm})"
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
