#! ruby
# How to view and validate a on_create / on_save trigger

t = perform = :create_reference
action = :on_create

# For the last activity log in some process
obj = al = ActivityLog::SleepAssignmentPhoneScreen.last
# Get the extra log type configuration
elt = al.extra_log_type_config
# Setup the conditional actions
ca = ConditionalActions.new elt.save_trigger, obj
# Validate that we can perform what it is that we want
res = ca.calc_save_action_if
puts res
#
config = elt.save_trigger[action][t]
puts config.to_json
