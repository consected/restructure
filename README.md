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


Filestore
========

Filestore is a component that provides upload, management and download of medical and project files.


Edit the file `config/initializers/nfs_store_config.rb`

Ensure that the following components are installed:

* bindfs
* fuse
* archivemount

If using a network filesystem mount, ensure it is mounted and appropriate bind mounts added, following this kind of pattern:

    FS_ROOT=/efs1
    FS_DIR=main
    MOUNT_ROOT=/mnt/fphsfs
    WEBAPP_USER=webapp
    mkdir -p /efs1
    getent group 599 || groupadd --gid 599 nfs_store_all_access
    getent group 600 || groupadd --gid 600 nfs_store_group_0
    getent group 601 || groupadd --gid 601 nfs_store_group_1
    getent passwd 600 || useradd --user-group --uid 600 nfsuser
    usermod -a --groups 599 $WEBAPP_USER
    mkdir -p $FS_ROOT
    mountpoint -q $FS_ROOT || mount -t efs -o tls fs-c302a188:/ $FS_ROOT
    mkdir -p $MOUNT_ROOT/gid600
    mkdir -p $MOUNT_ROOT/gid601
    mountpoint -q $MOUNT_ROOT/gid600 || bindfs --map=@600/@599 --create-for-group=600 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid600
    mountpoint -q $MOUNT_ROOT/gid601 || bindfs --map=@601/@599 --create-for-group=601 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid601


In production, consider creating a separate schema and moving the tables there, plus
updating the app search path.


Adding App Types to Filestore
---

A script is provided in the **scripts** repo under **app_scripts/filestore**

The NfsStore expects a specific structure for new App Types.

    APP_TYPE_ID=11

    FS_ROOT=/efs-prod
    FS_DIR=main
    APPTYPE_DIR=app-type-${APP_TYPE_ID}

    cd $FS_ROOT/$FS_DIR
    mkdir -p $APPTYPE_DIR/containers    
    chmod 770 $APPTYPE_DIR
    chmod 770 $APPTYPE_DIR/containers
    chown nfsuser:nfs_store_all_access $APPTYPE_DIR
    chown nfsuser:nfs_store_group_0 $APPTYPE_DIR/containers

**Note** the *nfs_store_all_access* group owner can be changed to another owner, such as *nfs_store_group_0* if access is to be controlled by the OS and user role *nfs_store group 600*
