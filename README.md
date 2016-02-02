Rails App for FPHS
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

A development environment can be created in a standalone VirtualBox using the **FPHS Build Box** described below, or in an existing
environment by running the script `./fphs-scripts/setup_dev.sh`






* Ruby version: 2.2.x (via RBENV)

* System dependencies: 
    * Postgres Client
    * Rails
    * memcached

* Configuration
    * RBENV setup
    * Run `rails new fpa1` before app copying to directory
    * bundle
    * RAILS_ENV=production bin/rake assets:precompile

* Database creation
    * Do NOT run `rake db:init` or any initialization on the database

* Database initialization
    * To create an initial administrator in the application, run `rake db:seed` then write down the generated password

* How to run the test suite
    * rspec is used for the development testing
    * Hoping to use bamboo in the future

* Services 
    * None

* Deployment instructions
    * TBD

