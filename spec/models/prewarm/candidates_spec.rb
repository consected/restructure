# frozen_string_literal: true

# Prewarm::Candidates unit tests (issue #1362 Stage 2, Phase 2).
#
# Verifies candidate selection collapses users into one representative per distinct
# (app_type, access variant), so warming does not repeat identical work per user - see
# Prewarm::Candidates class comment for why the variant key is a coverage heuristic, not
# a correctness mechanism (content addressing makes an over-sharing key merely cause a
# missed warm, never a wrong artifact).

require 'rails_helper'

RSpec.describe Prewarm::Candidates do
  include ModelSupport
  include UserSupport

  before(:all) do
    @admin, = create_admin
  end

  def make_user(sign_in_ago: 1.day, disabled: false, app_type: nil)
    user, = create_user(app_type:)
    user.update_columns(current_sign_in_at: sign_in_ago.ago, disabled:)
    user
  end

  it 'excludes users who have never signed in within the window' do
    app_type = Admin::AppType.active.first
    stale = make_user(sign_in_ago: Settings::PrewarmSignInWindowDays.days + 1.day, app_type:)
    fresh = make_user(sign_in_ago: 1.day, app_type:)

    reps = described_class.new.representatives
    users = reps.map(&:first)

    expect(users).to include(fresh)
    expect(users).not_to include(stale)
  end

  it 'excludes disabled users' do
    app_type = Admin::AppType.active.first
    disabled_user = make_user(disabled: true, app_type:)

    reps = described_class.new.representatives

    expect(reps.map(&:first)).not_to include(disabled_user)
  end

  it 'excludes template users' do
    template_user, = create_user(email: "prewarm-cand-#{SecureRandom.hex(4)}@template")
    template_user.update_columns(current_sign_in_at: 1.day.ago)

    reps = described_class.new.representatives

    expect(reps.map(&:first)).not_to include(template_user)
  end

  it 'collapses two users with identical roles and no user-specific access controls into one representative' do
    app_type = Admin::AppType.active.first
    user_one = make_user(app_type:)
    user_two = make_user(app_type:)
    Admin::UserRole.add_to_role(user_one, app_type, 'prewarm_role', @admin)
    Admin::UserRole.add_to_role(user_two, app_type, 'prewarm_role', @admin)

    reps = described_class.new.representatives
    matching = reps.select { |user, at| at.id == app_type.id && [user_one.id, user_two.id].include?(user.id) }

    expect(matching.size).to eq(1)
    expect(matching.first.first.id).to eq([user_one.id, user_two.id].min)
  end

  it 'gives a user with an extra user-specific access control row its own variant' do
    app_type = Admin::AppType.active.first
    plain_user = make_user(app_type:)
    special_user = make_user(app_type:)
    Admin::UserRole.add_to_role(plain_user, app_type, 'prewarm_role_2', @admin)
    Admin::UserRole.add_to_role(special_user, app_type, 'prewarm_role_2', @admin)
    Admin::UserAccessControl.create!(current_admin: @admin, app_type_id: app_type.id, user_id: special_user.id,
                                      resource_type: :table, resource_name: 'trackers', access: :read)

    reps = described_class.new.representatives
    matched_users = reps.select { |_, at| at.id == app_type.id }.map { |user, _| user.id }

    expect(matched_users).to include(plain_user.id, special_user.id)
  end

  it 'caps the number of representatives at Settings::PrewarmMaxVariants' do
    prev = Settings::PrewarmMaxVariants
    change_setting('PrewarmMaxVariants', 1)
    app_type = Admin::AppType.active.first
    3.times { |i| make_user(app_type:).tap { |u| Admin::UserRole.add_to_role(u, app_type, "cap_role_#{i}", @admin) } }

    reps = described_class.new.representatives

    expect(reps.size).to be <= 1
  ensure
    change_setting('PrewarmMaxVariants', prev)
  end
end
