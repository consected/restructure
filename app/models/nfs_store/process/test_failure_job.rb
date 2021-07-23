# frozen_string_literal: true

module NfsStore
  module Process
    # Background job exclusively used to test failures in RSpec testing
    class TestFailureJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :test_failure

      def perform(container_files, in_app_type_id, _activity_log = nil, _call_options = {})
        log 'Test failure'
        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        raise 'forced failure'
      end
    end
  end
end
