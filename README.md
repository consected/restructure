Rails App for FPHS (Zeus)
==================

This document provides information about:

* creating a development environment
* building the application
* FPHS specific database migration

For detailed information about the app and the requirements driving its functionality, view the Wiki at: 

https://open.med.harvard.edu/wiki/pages/viewpage.action?title=Web+Application+Development&spaceKey=FPHS

Security and Privacy
---

The FPHS Web Application functions in a highly secure environment and contains data that is considered highly sensitive due 
to the high profile of some of the people it represents. Although the app is not available on the public Internet, the same 
level of care must be taken in development and maintenance as for publicly-facing web applications.

In the past, all members of the development and QA team have been required to be complete Citi training. Check with a representative of the
FPHS team if in doubt.



Development Environment
---

Source control is managed by Subversion (a decision based on it being the only secure source control system maintained 
internally by the Informatics team early in the project). Subversion authorization is required to access the project at 

https://open.med.harvard.edu/svn/fphs-rails/

A development environment can be created in a standalone VirtualBox using the **FPHS Build Box** described below, or in an existing
environment by running the script `setup_dev.sh` available from:

https://open.med.harvard.edu/svn/fphs-rails/branches/phase3-1/fphs-scripts/setup_dev.sh

Credentials are standard open.med username and password.

The only supported browser for the app is Firefox running on Centos 6. Although everything should work fine on Chrome, the end users are limited to 
Firefox, so it is critical that development and testing is performed on this browser.


Development Process
---

Development of the FPHS app follows standard Rails approaches on a local development machine. The initial build includes dummy development data
ensuring that there are no privacy risks, while providing a reasonable variety of data.

Production deployment relies on the specified versions in `Gemfile.lock`. Ensure gems are updated prior to testing locally and building.

Automated testing relies on Rspec and Capybara, which is performed on the local development machine.

After testing, the process varies from standard Rails practices.


Source, database schemas, build scripts and the dummy development database are all maintained in Subversion. The main development branch currently is

https://open.med.harvard.edu/svn/fphs-rails/branches/phase3-1/

The development branch HEAD is expected to build at any time.


Building a Release Candidate
---

**Prerequisites:**

* Vagrant
* VirtualBox
* A clone of the *iteam* Ansible repository in Stash
 

**Set Up Build Configuration:**

Go to the Ansible setup directory 

    cd iteam/sysconfig/ansible/vagrant-fphs-webapp-build-box/

Run the setup script

    ./install-files.sh

Then copy the sample configuration
    
    cp extra_vars.sample.yml extra_vars.yml

Edit the `extra_vars.yml` file

**Process:**

After testing locally, ensure the project has been committed to Subversion to the main development branch specified in the `extra_vars.yml` file

The application build performs the following:

* deploys a Centos 6 server with all the prerequisites to build and run the application
* pulls the specified version of the code from the development branch
* installs bundled gems using versions in `Gemfile.lock`
* clobbers and builds the app Assets
* runs security test (bundle-audit and brakeman)
* creates a clean production environment 
* runs the production passenger server to validate the build is good
* dumps a new version of the schema definition to `dm/dumps/current_schema.sql`
* creates a clean test instance and runs Rspec tests that don't require Capybara (since there is no X server to run Firefox)
* generates a coverage report
* commits the results
* generates a new tag based on the `extra_vars.yml` **target_dot_version**, incrementing the final build version and 
copying the results to the /tags folder of the SVN repository (which is a deployable version through ansible to the target systems)
* sets up a development environment 
* creates an admin user on development 

After build is successful perform the following to validate success

From the current directory
 
    vagrant ssh
    # then run
    sudo -u passenger -i

    cd /var/opt/passenger/fphs

    RAILS_ENV=production ./add_admin.sh adminprod@test.com

    RAILS_ENV=development ./add_admin.sh admindev@test.com


If either of these block, you may need to stop the *Spring* server.

    bin/spring stop

Then re-run the commands.


Note the generated password for each file.

**Production environment**: browse to https://localhost:8443/admins/sign_in

Login with with adminprod@test.com and the adminprod password

**Development environment** (if required): browse to http://localhost:3080/admins/sign_in

Login with admindev@test.com and the admindev password 


Deploying to Shared Dev, Stage and Production
---

Deployment of code to real servers is performed by Ansible. On Stage and Production, database migrations are performed by the FPHS DBA.

To prepare the schema migrations, the schema from each server must be dumped to a file, retrieved locally and built. A modified 
`rake db:migrate task` is used to generate SQL that can be reviewed and run by the DBA (on Shared Dev - pandora.catalyst) the developer is able to 
run this directly.

The process is largely automated. 


Ensure you are connected to the appropriate VPN for the environment for which you wish to generate migrations

    cd <FPHS development directory>
    svn update
    chmod 770 fphs-scripts/gen_schema_migrations.sh    
    fphs-scripts/gen_schema_migrations.sh





