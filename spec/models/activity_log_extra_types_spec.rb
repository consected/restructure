require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log extra tyypes implementation', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    seed_database
    ::ActivityLog.define_models
    create_user
    create_item(data: rand(10000000000000000), rank: 10)
  end

  it "saves data into an activity log record" do

    u = @user

    al = ActivityLog.enabled.first

    al.extra_log_types =<<EOF
    step_1:
      label: Step 1
      fields:
        - select_call_direction
        - select_who
      users:

    step_2:
      label: Step 2
      fields:
        - select_call_direction
        - extra_text
      users:
        - #{u.id}

EOF

    c1 = al.extra_log_type_configs.first
    expect(c1.label).to eq 'Step 1'
    expect(c1.fields).to eq ['select_call_direction', 'select_who']

    c2 = al.extra_log_type_configs.last
    expect(c2.label).to eq 'Step 2'
    expect(c2.fields).to eq ['select_call_direction', 'extra_text']
    expect(c2.users).to eq [u.id]

    expect(ExtraLogType.fields_for_all_in al).to eq ['select_call_direction', 'select_who', 'extra_text']

  end

end
