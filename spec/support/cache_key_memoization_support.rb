# frozen_string_literal: true

module CacheKeyMemoizationSupport
  # A fresh view context holds a new skeleton signature instance, unlike the process-wide
  # ApplicationController.helpers proxy.
  def fresh_master_skeleton_cache_key(user)
    ApplicationController.new.helpers.master_templates_skeleton_cache_key(force_user_or_admin: user)
  end

  def reset_shared_helper_cache_key_memoization
    helper = ApplicationController.helpers
    # This proxy is process-wide, unlike the fresh view context used by a real request.
    helper.instance_variable_set(:@item_updates, nil)
    helper.instance_variable_set(:@partial_cache_key_access_control_timestamps, nil)
  end
end
