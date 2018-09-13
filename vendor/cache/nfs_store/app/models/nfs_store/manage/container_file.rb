module NfsStore
  module Manage

    # Abract class from which file metata that is stored in the database are subclassed
    class ContainerFile < NfsStore::UserBase

      self.abstract_class = true

      include HasCurrentUser

      def self.retrieval_type
        name.demodulize.underscore.to_sym
      end

      # Hook allowing the class to be reopened safely in the initializers
      ActiveSupport.run_load_hooks(:nfs_store_container_file, self)

    end
  end
end
