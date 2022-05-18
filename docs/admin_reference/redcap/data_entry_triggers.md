# Setting up the Data Entry Trigger (DET) for a project

## (FRAFT)

Go to the *Project Setup*

From *Enable optional modules and customizations* pick **Additional customizations**

Check the **Data Entry Trigger** and add the URL to the API endpoint.

If the server is not accessible externally, then one approach is to use the AWS API Gateway to provide a mechanism to call the ReStructure server API.
An example API url would be:

<https://abcdefg.execute-api.us-east-1.amazonaws.com/default/redcap-sqs-trigger>
