module Fphs
  module PlayerActionHandler
    extend ActiveSupport::Concern

    #
    # Player model specific associations for FPHS simple and advanced searches
    # This method can be removed if not required, or overridden
    def build_associations_for_searches
      # Advanced search fields
      @master.pro_infos.build
      @master.player_infos.build
      @master.addresses.build
      @master.player_contacts.build
      @master.trackers.build
      @master.tracker_histories.build
      @master.scantrons.build if defined? Scantron

      # NOT conditions
      @master.not_trackers.build
      @master.not_tracker_histories.build

      # Simple search fields
      @master.general_infos.build
    end
  end
end
