# Running **rspec** tests

Automated tests for the project use **rspec**. The have reasonable, but by no means complete, coverage of the project, and
in general some manual testing is recommended.

To make testing faster, and to facilitate some developer tasks, the following additional notes may assist.

## Before running test, setup the test machine

Some initial setup is expected by _rspec_ tests prior to being run, to ensure they have access to everything required.

First, setup the mount to the Filestore filesystem, which sets up appropriate bind mounts required to test group security
of the NFS storage.

    app-scripts/setup-dev-filestore.sh

By default, real AWS API calls are not made, instead calling mock versions for predictable results. Occasionally it may be desirable
to test against the real AWS API endpoints to ensure the integration remains operational. This can be done by setting the environment
variable

    export NO_AWS_MOCKS=true

If your tests should include real AWS API calls, and your AWS profile requires MFA, ensure your CLI has access with the
environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` appropriately set. If no MFA
is required, just ensure `AWS_PROFILE` is set.

To skip an AWS authorization check at the start of testing:

    export IGNORE_MFA=true

## Creating a test database

By default, the scripts use sudo to connect to the database as the superuser **postgres**. Run the following
script to create a test database using the current `db/structure.sql` schema script:

    app-scripts/create-test-db.sh 1

... or if connecting to the database as the superuser over IP rather than OS user **postgres**

    USE_PG_HOST=localhost USE_PG_UNAME=postgres app-scripts/create-test-db.sh 1

The argument **1** ensures only a single database is created. For setup of multiple test databases to
support parallel testing, described below, run without any arguments.

    app-scripts/create-test-db.sh

... or if connecting to the database as the superuser over IP rather than OS user **postgres**

    USE_PG_HOST=localhost USE_PG_UNAME=postgres app-scripts/create-test-db.sh

This will create a test database for every available processor or core on the test machine.

## Dump the database structure to a script

Since the current `db/structure.sql` is used to make new test databases,
you may find it useful to create an up to date version from your latest
development database before creating a test database.

The following will dump just the required schemas, rather than
everything in the development database, making subsequent creation faster.

    FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data FPHS_LOAD_APP_TYPES=1 bundle exec rake db:structure:dump

**NOTE:** the `db/schema.rb` file is not used, and if it is present it does not
represent a complete database and should not be used.

## Dropping a test database

Although the majority of tests run within a transaction and clean up after the example has run, some setup is performed
outside of transactions. Specifically, database configurations and user data is created outside transactions so that
_rspec/features/_ tests can see the data in the separate Selenium processes. This can lead to the test database becoming
bloated and slowing down simple tests after repeated runs.

    app-scripts/drop-test-db.sh

This will drop test databases for all processors / cores on the machine.

## Migrations

The test database should run migrations automatically, although this appears to not always be reliable.

Migrations of the test database become harder when there are multiple test databases to maintain. For this reason it
is easier to drop and create multiple databases using the latest structure, rather than attempting to migrate each by
hand. For fast testing during development, when running a single _\_spec.rb_ file, migrating the main test database as
normal will suffice. Remember to drop and create all test databases when it comes to run a full coverage parallel test.

    RAILS_ENV=test FPHS_LOAD_APP_TYPES=1 bundle exec rake db:migrate

## Running single test

Single tests can be run as usual with rspec:

    bundle exec rspec spec/path...

After the first run, use the following to skip additional setup that happens within the `rails_helper.rb`

    SKIP_APP_SETUP=true SKIP_BROWSER_SETUP=true bundle exec rspec spec/path...

This will skip app, db and virtual display browser (for `spec/features`) setup, assuming they are already in place.
It is not recommended to use these environment variables when starting parallel tests.

## Running parallel tests

The **parallel** test gem is used to speed up testing considerably. First drop and create test databases for all cores,
then run:

    app-scripts/parallel_test.sh

This will run a subset of the full test suite on each processor / core of the machine.

To view failing tests, in a separate console run:

     less tmp/failing_specs.log

This log file is cleared shortly after running `parallel_test.sh`.

**NOTE**: the **brakeman** static tester is run at the start of a parallel test, to ensure testing is not being run against
dangerous code. To skip the _brakeman_ test, run instead:

    NO_BRAKEMAN=true app-scripts/parallel_test.sh

A subset of the full test suite can be run by specifying a path as the first argument. For example, the following will just
run the redcap model specs.

    NO_BRAKEMAN=true app-scripts/parallel_test.sh spec/models/redcap

## Running Javascript tests with Jasmine

[jasmine-browser-runner](https://github.com/jasmine/jasmine-browser-runner) is used for Spec style Javascript testing. To simplify
running of the tests, use:

    app-scripts/jasmine-serve.sh

After a few seconds this will open a Firefox window with the test results. Firefox is used, since it doesn't enforce a security feature
that blocks debugging of Jasmine in the browser debugger (either by placing a breakpoint or using the `debugger;` instruction in the code.)

For automated testing, instead use:

    app-scripts/jasmine-serve.sh headless

This should run the tests, closing the browser window after use.
