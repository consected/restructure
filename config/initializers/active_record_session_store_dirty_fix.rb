# frozen_string_literal: true

# Fix for rails/activerecord-session_store#236 - "2.3.0 drops in-place nested session writes
# (changed? misses mutations)": https://github.com/rails/activerecord-session_store/issues/236
#
# activerecord-session_store 2.3.0's Session#data= compares the incoming data against `self.data`,
# which is the same (already-mutated) memoized object whenever a caller mutates a nested key in
# place - e.g. Devise's Timeoutable hook does `warden.session(scope)['last_request_at'] = ...`.
# That comparison is always false, so `changed?` never becomes true and `write_session`'s "skip
# save when unchanged" optimization silently drops the update, breaking session inactivity timeout
# refresh - fixes #1345
#
# This overrides `data=` to compare against a freshly deserialized copy of the raw DB column
# instead, so in-place nested mutations are correctly detected as changes.
#
# Remove this file once upstream ships a fix and we bump the gem version - see follow-up #1352.
Rails.application.config.to_prepare do
  ActiveRecord::SessionStore::Session.class_eval do
    def data=(data)
      attribute_will_change!('data') if data != self.class.deserialize(read_attribute('data'))
      @data = data
    end
  end
end
