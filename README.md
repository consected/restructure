# ReStructure

**ReStructure** is an application platform that helps researchers structure research study data and activities, to track, recruit, screen, navigate and review human subjects.

The platform is flexible, offering valuable features to any organization requiring flexible CRM style data management, case management and document management.

Most requirements are met through configuration, and the application is completely open-source allowing customization in code if needed.

The philosophy of the application is to provide an application layer on top of a well-structured database and filesystem, so that other services and applications can view and manipulate files and data safely, avoiding lock-in, and allowing simple integration with other systems in an organization.

## Development and contributing

**ReStructure** was built by Harvard Medical School to support the Football Players Health Study. The research team uses multiple applications built on the **ReStructure** platform (known internally as Athena and Zeus) on a daily basis, to manage highly sensitive study and project processes, personally identifiable information (PII), protected health information (PHI), documents and medical imaging files. Development has been running since 2015.

The platform has been generously open-sourced by Harvard in the hope that other research studies can benefit from a modern end-user focused application. There are no restrictions on who can download, fork or use the project.

The **ReStructure** open-source project is maintained by [Consected](https://www.consected.com), incorporating new features from the Harvard codebase into the project and vice versa.

If you find a bug, please add an issue with details of how to reproduce it. If you find a **security issue**, please add an issue indicating that there is a security issue (but don't share the full details) and also email <admin@consected.com> with a clear subject line that this is a security issue related to the ReStructure project, and full details of the issue.

Contributions from the community are welcomed if they fit the overall approach of the project. Small requests for changes and new functionality may be considered, but please remember that this project is free software managed by volunteers. Although Harvard has donated the platform as open source software, the development of new features within Harvard are exclusively to support the _Football Players Health Study_, although they are typically intended to be generally useful.

Developers should bear in mind that the platform has been developed over many years, built with features being added in very rapid, and sometimes time-pressured sprints. Code is not always as well structured or documented as we would like, and occasionally may include incomplete features. The aim of the contributors is to improve this with a minimum of breaking changes. See [Future development themes](#future-development-themes) for the themes we have in mind.

## Features

**ReStructure** is an application that attempts to provide enterprise application capabilities in a modern, open platform, without vendor lock-in. The key features are hard to describe conceptually (so take a look at the demo), but this list attempts to highlight them:

### Security

Two-factor authentication, separate admin logins, password expirations, lockouts to prevent brute-force attacks, granular activity logging, protect and audit user accounts and actions. Static code analysis and security scanning of live systems check for possible vulnerabilities.

### Usability

Provide a highly usable user interface that can be used without training, and provides consistent, usage patterns for data and process management.

### CRM structured for research data

The platform provides CRM functionality as a core feature. Tracking of interactions with participants ensures researchers can see the full context of previous communications, while ensuring compliance with research policies.

### Process management, case management and activity logging

The ability to define processes that can enforce short term workflows (such as a screening process) and long term case management, such as all the activities related to a participant over the course of a study.

### Define data structures and forms

Data attributes can be easily specified, and form display rules define conditions on what must be displayed based on the entry of other attributes.

### Granular rules and authorizations

Any data related to a participant can be used to enforce other activities that can (or must) be performed, and allow or deny different user roles access to view, edit or create blocks of information and activities. This allows policies for data access to be enforced based on other actions having been completed, and locking down data once finalized.

### Modular applications

Upload an application configuration into a development environment, refine it, download the definition then upload into the staging or production environment.

### Relational database

All data, including change history, is captured in a relational database that can be accessed and manipulated by standard database tools, analytics scripting languages (R, Python) and applications that have database connectivity built in (SAS, SPSS, Stata, etc)

### Structured, secured data

Rather than disparate systems generating flat files of data (for example REDCap), the relational database structure allows natural organization of data, and the ability to segment and secure portions of the data at a user level (both inside the app and for direct database users)

### File management

Regular desktop files and sequences of MRI images can be rapidly captured into the system, through the user interface or via programmatic APIs (allowing automated submission from other locations) as an alternative to more complex XNAT servers or separate electronic document and records management systems (EDRMS)

### Dashboards and reports

Configure searches and reports that are specific to individual roles. Graphical dashboards can also be defined, showing typical charts based on live data.

### Customization

In some scenarios there are requirements that may not be possible with configuration. The open design of the platform allows for extensions to be developed, which may either feed back into the open-source project, or may be specific to the project they are developed for.

### REDCap integration

Administrators are able to define projects to transfer data from, through the REDCap API. Routine data
pulls may be scheduled to provide automated transfers of survey and data collection instrument data
to the relational database. REDCap metadata pulled through the integration is used to automatically set
up relational database tables and maintain a central data dictionary.

### Integrate data from external sources

The design provides a clear separation between external or static data captured by third-parties, and live data from internal operations that may change and be added routinely. Data transfers can be automated through customization, or directly by uploads through the web interface.

## Technology

The **ReStructure** application is a complete _Ruby on Rails_ 6 application with a single-page application Javascript front end, running against a _PostgreSQL_ database. A full end-user UI follows the application configurations, a configurable API is available, and an admin UI provides access to all configuration options, with all settings saved in the database.

The database design follows common Rails conventions, with an easily understandable relational database model. As new configurations are made, new database table migrations are generated automatically, allowing rapid development, and clean deployment to production. PostgreSQL is the only supported database.

The default application server is _Passenger_, although _Puma_ is used in development and may be selected for production.

_Memcached_ provides caching of performance and to relieve the load on the application server and database. Central or individual app-server caches may be used.

Authentication is provided by [Devise](https://github.com/heartcombo/devise), with optional two-factor authentication [devise-two-factor](https://github.com/tinfoil/devise-two-factor). End-user and admin profiles are managed separately. API tokens are optionally available for user profiles, to allow integration or disparate systems, provided by [Simple Token Authentication](https://github.com/philayres/simple_token_authentication.git).

File management for document and image files is handled through a layer on top of NFS, allowing unlimited storage through elastic storage such as AWS EFS. Linux groups provide a course level of security, enabling direct filesystem access to files to be controlled. This functionality started as a separate gem, but it was easier to keep it more integrated with the overall project. It could be separated again if a developer had the desire to do so.

Background tasks, especially around notifications and file processing, are coordinated through [delayed_job](https://github.com/collectiveidea/delayed_job). Jobs are stored in the Postgres database.

AWS APIs are used to provide email and SMS notifications.

For faster testing, [parallel_tests](https://github.com/grosser/parallel_tests) is used.

## Set up development environment

The app is easy to set up. First clone the server repo (this one), app configs, and build container.
Then set up the database.

    git clone https://github.com/consected/restructure.git
    git clone https://github.com/consected/restructure-build.git
    git clone https://github.com/consected/restructure-apps.git
    git clone https://github.com/consected/restructure-docs.git

### Setup the database

It is highly recommended to use a consistent version of Postgres client on all machines. Currently we are using Postgres 12.
To ensure `psql` and all `rake db:structure:dump` works as expected, set the path to Postgres 12 binaries explicitly.

    export PATH=/usr/lib/postgresql/12/bin:${PATH}

Now create a development environment database

    DB_USER=$(whoami)
    sudo -u postgres psql -c "create database restr_development owner ${DB_USER};"

Note that we create the database using psql, to avoid Rails initializer errors breaking the process.

    psql -d restr_development < db/structure.sql
    bundle exec rake db:migrate
    bundle install
    yarn install

If you would like to populate the database with demo data:

    unzip db/demo-data.zip -d db/
    psql -d restr_development < db/demo-data.sql
    rm db/demo-data.sql

Seed the database (even if you have populated demo data):

    bundle exec rake db:seed

### Setup a simulated Filestore filesystem

File storage in production is typically on an NFS filesystem. In development without NFS we simulate
a separate filesystem with some internal mounts. Some directories will be created in the user's home directory
to make this work.

    app-scripts/setup-init-mounts.sh
    app-scripts/setup_filestore_app.sh 1
    app-scripts/setup-dev-filestore.sh

A Fuse filesystem can also be used as external storage rather than
the home directories, and will be used if there is a Fuse filesystem mounted at `/media/$USER/Data` by skipping
`app-scripts/setup-init-mounts.sh`

### Setup a new admin user

Set up a new admin user:

    RAILS_ENV=development app-scripts/add_admin.sh <email address>

_Record the password that is returned._

### Run the server

Run the server:

    FPHS_2FA_AUTH_DISABLED=true bundle exec rails s

Go to [http://localhost:3000/admins/sign_in?secure_entry=access-admin](http://localhost:3000/admins/sign_in?secure_entry=access-admin)

Login with the admin username and the password that was returned previously.

In the admin panel, go to the link _Usernames & Passwords_.
Click the button **+ Manage user** to add a user, enter the email **test@test**
and be sure to record the password that is generated.

Click **admin menu** button, click _App Types_ link, then in the _Upload a configuration file_ block,
choose the file `db/dumps/zeus_config.yaml` then click the **Save Changes** button.

Assuming this was successful, logout of the admin panel.

Stop the Rails server, then restart it.

Back in the browser you will be at the user login screen. Login as **test@test**

Now login as the user you have just created.

Welcome to **ReStructure**!!!

### Logging in as a user

For future logins as a user, just go to [https://localhost:3000](https://localhost:3000). If you are an administrator, you will be able to access the admin panel login through the wrench icon in the nav bar, or using the link above.

### Clean up the development DB

To clean all data, including admins and user, run:

    psql -c "drop database restr_development;"
    psql -c "create database restr_development;"
    psql -d restr_development < db/structure.sql
    bundle exec rake db:seed
    RAILS_ENV=development app-scripts/add_admin.sh <email address>

### Branches for development and release

The project previously used [git-flow](https://skoch.github.io/Git-Workflow/) to organize releases. This is no longer the case, and the [Build for deployment](#build-for-deployment) process handles branching and tagging of releases. Where possible, github Pull Requests should be used to contribute features and fixes back to the primary repo.

Active development should be within its own branch, which should be merged back into the _develop_ for integration. The _new-master_ branch contains tagged versions that represent viable production releases.

## Build for deployment

Deployment to any environment that supports Rails should be reasonably easy. To build a self-contained package of gems and Javascript components, a separate repo is provided: [restructure-build](https://github.com/consected/restructure-build). This provides a Docker container, based on CentOS, that sets up a full Rails and PostgreSQL environment. It builds production packages for gems and Yarn Javascript packages.

To build, simply clone _restructure-build_ to the same parent directory as the **ReStructure** project. Then from `ReStructure` run

     app-scripts/release_and_build.sh

This will automatically create a release with the patch number up-versioned - see [CHANGELOG.md](CHANGELOG.md)

When changes are integrated back into the primary repo, a release with a new minor version should be created. This can be done with:

     app-scripts/release_and_build.sh minor

If changes are ever made to any of the _restructure-build_ scripts, the Docker containers can be cleaned and rebuilt with:

     app-scripts/release_and_build.sh clean <optional: minor>

## Testing

Rspec tests are available. To set up a test database, first get a dump of the current
development database structure (if you have made migrations)

    export PATH=/usr/lib/postgresql/12/bin:${PATH}
    FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data bundle exec rake db:structure:dump

To allow easier DB authentication for tests, make entries into the `~/.pgpass` file
to enable automatic authentication with your DB password, such as:

    localhost:5432:restr_test:username:mysecretpw

To create a single test database for running rspec directly:

    # On Mac, between Docker containers, or just when connecting the # DB over IP rather than Linux sockets:
    export USE_PG_HOST=localhost
    export USE_PG_UNAME=postgres

    app-scripts/create-test-db.sh 1

Make sure the Filestore mounts are in place:

    app-scripts/setup-dev-filestore.sh

Ensure you have Firefox and the most appropriate geckodriver installed:

- On Ubuntu 22.04 and above, Firefox is a Snap package. After installing, run `sudo ln -s /snap/bin/geckodriver /usr/local/bin` to link to the snap geckodriver
- On Flatpak installed Firefox, see: <https://firefox-source-docs.mozilla.org/testing/geckodriver/Usage.html#Running-Firefox-in-an-container-based-package>
- On locally installed Firefox, install geckodriver from the standard releases: <https://github.com/mozilla/geckodriver/releases> - then run the script below

    GECKODRIVER='<https://github.com/mozilla/geckodriver/releases/download/v0.32.0/geckodriver-v0.32.0-linux64.tar.gz>'
    wget -O geckodriver.tar.gz ${GECKODRIVER}
    tar -xvf geckodriver.tar.gz
    mv geckodriver /usr/local/bin/
    chmod 777 /usr/local/bin/geckodriver

Run the test suite:

    IGNORE_MFA=true bundle exec rspec

Or if you want to use real AWS calls, set `AWS_PROFILE` then run:

    bundle exec rspec

For more rspec information, check [running rspec tests](docs/dev_reference/main/running_rspec_tests.md)

It is recommended to periodically drop and recreate the test database, since over time tests will slow down.

    # On Mac, between Docker containers, or just when connecting the # DB over IP rather than Linux sockets:
    export USE_PG_HOST=localhost
    export USE_PG_UNAME=postgres

    app-scripts/drop-test-db.sh 1 ; app-scripts/create-test-db.sh 1

### Running tests against AWS APIs

There are some tests that attempt to use an AWS account to send SMS notifications. These have been mocked out,
although at least one should run an SMS notification as an integration test, and to allow a comparison against
CloudWatch results. Setup your `~/.aws/config` and `~/.aws/credentials` files appropriately to allow tests to run against the live AWS API. Then make this the preferred profile the default:

    export AWS_PROFILE=<profile name in ~/.aws/config>

On well secured AWS accounts, you may have MFA configured. Either setup your credentials file to include the appropriate
`aws_access_key_id` and `aws_secret_access_key` for these, or alternatively don't attempt to authenticate (and accept certain tests will fail.)

The environment variable `IGNORE_MFA=true` prevents AWS multifactor authentication blocking the startup of the tests.

### Parallel test

For faster testing, _parallel_tests_ provides parallelization of Rspec, although does introduce some quirks into the testing, with false positives appearing. Better structuring of the spec tests will eventually resolve this, but in the meantime a few focused singular rspec calls will validate those that fail.

The following will create a set of test databases for the number of processor cores on your machine:

    # On Mac, between Docker containers, or just when connecting the # DB over IP rather than Linux sockets:
    export USE_PG_HOST=localhost
    export USE_PG_UNAME=postgres

    app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh

This will have created the database with the owner matching your current OS user. To allow easier DB authentication for tests, make entries into the `~/.pgpass` file
to enable automatic authentication with your DB password, such as:

    localhost:5432:restr_test:username:mysecretpw
    localhost:5432:restr_test2:username:mysecretpw
    ...
    localhost:5432:restr_test8:username:mysecretpw

Then run the parallel tests:

    app-scripts/parallel_test.sh

To review failed results:

    less -r tmp/failing_specs.log

The easiest way to deal with migrations is to drop the test database and recreate.

    # On Mac, between Docker containers, or just when connecting the # DB over IP rather than Linux sockets:
    export USE_PG_HOST=localhost
    export USE_PG_UNAME=postgres

    app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh

## Pull Requests

Contributions back to upstream ReStructure are much appreciated. Assuming you have forked from <https://github.com/consected/restructure>
then this is one way to produce clean pull requests.

For each feature / fix ensure you only have the relevant commits in a branch. If there is other activity on your remote fork,
such as commits produced building the platform for a specific environment, or local changes specific to your environment, creating a
PR will a feature branch might lead to junk that the upstream repo doesn't want. Do avoid this, you'll need to rebase your branch on
the state of the upstream/develop branch that will be receiving the PR commits.

```sh
git checkout -b up-develop upstream/develop
git branch --set-upstream-to=origin
git checkout ${feature-branch}
git rebase --onto up-develop ${commit-prior-to-first-in-feature-branch}
git push --force
```

## Future development themes

Upgrade to Rails 7.

The Javascript UI is a custom reactive front end. Near the beginning of development a simple platform was developed, which is tightly bound to the operation of the backend. Although completely functional without changes (except obviously for addition of new features), a long term vision is to replace the UI with Vue.js or React running against the existing API.

API authentication is currently token based. Adding JWT authentication to support a new UI makes sense.

Provide more structured admin panel configuration, especially around case management and processes (activity logs), forms and data structures (dynamic models), rather than just YAML document configurations.

Refactor and comment code to provide a better future development environment.

Provide better test coverage.

## Support

Support from the community may be available. Create an issue and clearly describe what you need.

Alternatively, [Consected](https://www.consected.com) can provide additional deployment assistance and full support packages.

## Contributors

- Harvard Medical School [Football Players Health Study at Harvard University](https://footballplayershealth.harvard.edu/)
- [Consected LLC](https://consected.com)
- Harvard Pilgrim Health Care Institute [Project Viva](https://www.hms.harvard.edu/viva/)

## License

This code is property of Harvard University
and made available as open source under the
BSD-3 license
(<https://opensource.org/licenses/BSD-3-Clause>).

Copyright 2020 Harvard University

Redistribution and use in source and binary
forms, with or without modification, are
permitted provided that the following
conditions are met:

1. Redistributions of source code must retain
   the above copyright notice, this list of
   conditions and the following disclaimer.

2. Redistributions in binary form must
   reproduce the above copyright notice, this
   list of conditions and the following
   disclaimer in the documentation and/or other
   materials provided with the distribution.

3. Neither the name of the copyright holder
   nor the names of its contributors may be used
   to endorse or promote products derived from
   this software without specific prior written
   permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE
