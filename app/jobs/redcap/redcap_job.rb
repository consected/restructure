# frozen_string_literal: true

module Redcap
  #
  # Skeleton job for REDCap retrievals.
  class RedcapJob < ApplicationJob
    queue_as :redcap

    include RedcapJobHandler
  end
end
