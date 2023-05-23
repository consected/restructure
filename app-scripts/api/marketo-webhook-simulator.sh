#!/bin/bash
# Pretend to be a Marketo webhook

if [ -z "${upload_user_token}" ]; then
  cat << EOF
Usage:
upload_user_token=<reset password to get a new token> \\
upload_server=https://a-server.tld \\
upload_user_email=marketo_webhook@system-user \\
upload_app_type=4 \\
post_email=phil-test14@test.tst\\
post_event_type=bounced \\
post_received_data='dynamic_model_marketo_trigger[received_data]={"email_invalid":"{{lead.Email Invalid}}", "email_invalid_cause":"{{lead.Email Invalid Cause}}", "trigger_category":"{{trigger.category}}","trigger_details":"{{trigger.details}}"}' \\
app-scripts/api/marketo-webhook-simulator.sh

Set DEBUG environment variable to any value to get full debug messages and JSON results
EOF
  exit
fi

if [ "$DEBUG" ]; then
  echo "Getting result for simulating a webhook call from Marketo"
fi

curl -XPOST \
  "${upload_server}/dynamic_model/marketo_triggers.json?use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}" \
  -F "dynamic_model_marketo_trigger[email]=${post_email}" \
  -F "dynamic_model_marketo_trigger[event_type]=${post_event_type}" \
  -F "dynamic_model_marketo_trigger[received_data]=${post_received_data}"
