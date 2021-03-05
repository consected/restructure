# frozen_string_literal: true

module NfsStore
  #
  # Simplify the process of creating filestore containers related to
  # admin resources.
  # User access controls and file filters on the container are defined by
  # the user related to the current admin, so it is necessary to set up
  # the appropriate roles, etc for each user related to an admin that needs to
  # access or create containers and files.
  module ForAdminResources
    extend ActiveSupport::Concern

    #
    # Create a file store container referenced by this project admin record,
    # with the name of the project admin record as its name
    # @return [NfsStore::Manage::Container]
    def create_file_store
      master.current_user = file_store_user
      container = NfsStore::Manage::Container.create_in_current_app user: file_store_user,
                                                                    name: name,
                                                                    extra_params: {
                                                                      master: master,
                                                                      create_with_role: nfs_role
                                                                    }
      container.current_user = file_store_user
      ModelReference.create_with self, container, force_create: true

      @file_store = container
    end

    #
    # Retrieve the file store container
    # @return [NfsStore::Manage::Container]
    def file_store
      @file_store ||= ModelReference.find_referenced_items(self, record_type: 'NfsStore::Manage::Container').first
    end

    #
    # Master record to be used to contain filestore containers
    # @return [Master]
    def master
      Settings.admin_master
    end

    def master_id
      master.id
    end

    def current_user
      master.current_user || file_store_user
    end

    def master_user
      current_user
    end

    private

    #
    # The user that matches the current admin
    # This is used to allow file store to work
    # @return [User]
    def file_store_user
      return @file_store_user if @file_store_user

      @file_store_user = current_admin.matching_user
      raise FphsException, "no matching user for admin #{current_admin}" unless @file_store_user

      @file_store_user
    end

    def nfs_role
      Settings.admin_nfs_role
    end
  end
end
