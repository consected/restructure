# API Reference

## Introduction

The ReStructure API is a REST API allowing access to all aspects of user functionality. It follows the same structure as the endpoints accessed by the UI. Most of the actions are CRUD operations, with some additional actions where necessary.

## Authentication

Simple authentication uses a shared secret. Pass the API credentials as HTTP headers
and set the app type as a URL parameter:

```text
X-User-Email: <api user email address>
X-User-Token: <shared secret>
```

`use_app_type=<app-type name or id>`

As a fallback, you can alternatively pass the email and token as query parameters.
This risks leaking sensitive information in URLs and server logs.

`?user_email={{user_email}}&user_token={{user_token}}`

## Endpoints

Since new resources may be generated through the configuration of dynamic definitions (dynamic models, external identifiers and activity logs), the API definition is not static.

In the admin panel, each of the dynamic definitions and the reports admin has an API tab, detailing us of the API.

Additionally, all the available API endpoints may be listed dynamically on the target server using:

`app-scripts/api-endpoint.sh` to generate a full set of routes

Supply a comma separated list of app types as the first argument to filter the routes by.

`app-scripts/api-endpoint.sh 1,2`  # routes for app types 1 and 2 only

NOTE: this may take some time to return, since the environment has to be fully loaded to include all the dynamic definitions.

## Sample Scripts

See the `/app-scripts` folder and `spec/system/api` folder for sample scripts calling the API.

## Calling from Save or Batch Triggers on a remote server

Since the API is a standard REST endpoint, the trigger `pull_external_data` allows a remote server to get data from, and send data to, a remote ReStructure server.
