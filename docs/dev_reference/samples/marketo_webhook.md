# Marketo Webhook

This example shows how Marketo can call back to ReStructure through a webhook to add a record and potentially trigger other actions (through dynamic definition `save_trigger:` configurations).

AWS Lambda may optionally be used to support processing the message and passing it on to the ReStructure server within a private network, not accessible through a direct public Internet call.

This is adaptable for other third-party systems that support webhooks, such as Redcap, Slack, etc.

## Marketo Configuration when calling direct

Within Marketo, go to Admin | Webhooks. Add a webhook with the following details

URL: `https://<your ReStructure domain>/dynamic_model/marketo_triggers.json?use_app_type=<RefDataAppType>&user_email=<UserEmail>&user_token=<UserToken>`
Payload Template:`{"email":{{lead.Email Address}},"event_type":{{lead.ReStructure Status}},"received_data":{"email_invalid":{{lead.Email Invalid}}, "email_invalid_cause":{{lead.Email Invalid Cause}},"trigger_details":{{lead.ReStructure Status Details}} } }`
Request Token Encoding: `JSON`
Request Type: `POST`
Response Format: `JSON`

## Using Lambda

### Marketo Configuration

Within Marketo, go to Admin | Webhooks. Add a webhook with the following details

URL: `https://<your Lambda URL endpoint>.lambda-url.us-east-1.on.aws/`
Payload Template:`{ "dynamic_model__marketo_trigger": {"email":{{lead.Email Address}},"event_type":{{lead.ReStructure Status}},"received_data":{"email_invalid":{{lead.Email Invalid}}, "email_invalid_cause":{{lead.Email Invalid Cause}},"trigger_details":{{lead.ReStructure Status Details}} } } }`
Request Token Encoding: `JSON`
Request Type: `POST`
Response Format: `JSON`

### Lambda Configuration

Go to AWS Lambda and add a new Lambda function.

Configurations:

- Runtime: `python`

- Advanced Settings
  - Enable function URL, with *Auth type* `NONE`
  - Enable VPC
    - Pick your private VPC and a subnet that has an Internet gateway
    - Add a security group with outbound rules that have a destination (IP or Security Group) for your ReStructure server / load balancer
    - Also, enable the Security Group for your ReStructure server to allow incoming traffic from the new security group you have added

If desired, use Asynchronous invocation, if you are not worried about waiting for "success" from ReStructure and just want a fast response.

In ReStructure, add a system user and obtain an API token.

Add the lambda_function code, below:

```python
import sys, traceback
import json
import boto3
import base64
from urllib.parse import parse_qs
import urllib3


HostUrl = 'https://<restructure domain>'
UserEmail = 'marketo_webhook@system-user'
UserToken = '<user token for system user>'
RefDataAppType = '<your app id>'


def lambda_handler(event, context):
    res = None

    try:
        is_b64 = event['isBase64Encoded']
        body = event['body']
        
        if is_b64:
            body = base64.b64decode(body)
            body = body.decode('ascii')
        
        record = json.loads(body)
        
        attrs = {}
        email = record.get('email')
        event_type = record.get('event_type')

        if email is None or event_type is None:
            res = {
                'statusCode': 401,
                'body': f'Error: bad request {body}'
            }
            return res

        received_data = record.get('received_data', '')


        url = f'{HostUrl}/dynamic_model/marketo_triggers.json?use_app_type={RefDataAppType}&user_email={UserEmail}&user_token={UserToken}'
        form_data = {
            "dynamic_model_marketo_trigger[email]": email,
            "dynamic_model_marketo_trigger[event_type]": event_type,
            "dynamic_model_marketo_trigger[received_data]": json.dumps(received_data)
        }
        
        http = urllib3.PoolManager()        
        r = http.request('POST', url, fields=form_data)
        
        res = {
            'statusCode': 200,
            'body': {
                'backend_status': r.status
            }
        }

    except Exception as ex:
        res = {
            'statusCode': 500,
            'body': {
                'Error': str(type(ex))
            }
        }
        traceback.print_exc(file=sys.stdout)

    return json.dumps(res)

```

To facilitate testing, take a look at the sample [webhook simulator](/app-scripts/api/marketo-webhook-simulator.sh)
