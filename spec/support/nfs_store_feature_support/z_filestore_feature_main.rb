# frozen_string_literal: true

# Main module for NFS Store filestore system specs.
# Combines setup and UI action modules for comprehensive filestore testing.
#
# Usage:
#   describe 'Filestore operations', type: :system do
#     include FilestoreFeatureMain
#     ...
#   end
require_relative '../nfs_store_support'
require_relative 'filestore_setup'
require_relative 'filestore_ui_actions'

module FilestoreFeatureMain
  include FeatureHelper
  include FeatureSupport
  include ModelSupport
  include MasterDataSupport
  include PlayerContactSupport
  include UserActionsSetup
  include NfsStoreSupport

  include FilestoreSetup
  include FilestoreUiActions
end
