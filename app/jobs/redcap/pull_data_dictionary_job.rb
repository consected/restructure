module Redcap
  class PullDataDictionaryJob < ApplicationJob
    queue_as :default

    def perform(user); end
  end
end
