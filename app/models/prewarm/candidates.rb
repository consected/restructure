# frozen_string_literal: true

# Candidate selection for template prewarming (issue #1362 Stage 2).
#
# After content-addressing (Stage 1, #1377), individual compiled templates/partials are
# already shared by every user whose rendered content is identical. Warming one
# representative user per distinct (app_type, access variant) therefore populates every
# artifact that any matching user would need, at a fraction of the cost of warming every
# user x app type.
#
# The variant key is a COVERAGE HEURISTIC, not a correctness mechanism: because
# artifacts are content-addressed, an over-sharing key (grouping two users who actually
# render different content) can only cause a MISSED warm - a real request then compiles
# it as it does today - never a wrong or cross-contaminated artifact.
module Prewarm
  class Candidates
    def self.representatives
      new.representatives
    end

    # @return [Array<Array(User, Admin::AppType)>] one (user, app_type) pair per distinct
    #   variant, capped at Settings::PrewarmMaxVariants
    def representatives
      variants = {}

      candidate_users.find_each do |user|
        Admin::AppType.all_available_to(user).to_a.each do |app_type|
          key = variant_key(user, app_type)
          existing = variants[key]
          variants[key] = [user, app_type] if existing.nil? || user.id < existing.first.id
        end
      end

      variants.values.first(Settings::PrewarmMaxVariants)
    end

    private

    def candidate_users
      User.active.not_template
          .where('current_sign_in_at > ?', Settings::PrewarmSignInWindowDays.days.ago)
    end

    def variant_key(user, app_type)
      role_names = Admin::UserRole.active_app_roles(user, app_type:).order(:role_name).pluck(:role_name)
      access_rows = Admin::UserAccessControl
                    .active
                    .where(user_id: user.id, app_type_id: app_type.id)
                    .order(:resource_type, :resource_name, :access)
                    .pluck(:resource_type, :resource_name, :access)
      Digest::SHA256.hexdigest([app_type.id, role_names, access_rows].to_json)
    end
  end
end
