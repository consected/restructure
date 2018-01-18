Rails App for FPHS (Zeus)
==================

The **Zeus** App provides CRM and activity tracking functionality for the
Football Players Health Study (FPHS) team.

### Build, Test and Deployment

Build, test and deployment is by Ansible, with full details here:
https://github.com/hmsrc/ansible-playbooks-fphs-webapp

The same Ansible roles can be used to create a self-contained Vagrant server for
development, avoiding the need to get all the prerequisites satisfied locally.

### Multiple Repos

It should be noted that as of Zeus Phase 5, two Git repos are being used.

1. Harvard Catalyst Bitbucket: **development**

    https://open.med.harvard.edu/stash/projects/FPHSAPPS/repos/fphs-rails/browse

2. HMRC Github: **production-ready releases**

    https://github.com/hmsrc/fphs-rails-app


The development repository contains all code, including release-ready code. Releases are tagged in the form x.y.z

The production-ready release repository contains only code that has been built and tested. It is tagged in the same form and with the same release numbers as the development repository. Deployments made by Ansible are from this repo.
