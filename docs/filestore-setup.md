# Filestore Setup

Filestore is a component that provides upload, management and download of medical and project files. This document is targeted at
production use of Filestore on a Linux platform. For development with Filestore on macOS, see [README.md](../README.md) and
`app-scripts/setup-dev-filestore.sh`

Edit the file `config/initializers/nfs_store_config.rb`

Ensure that the following components are installed:

- bindfs
- fuse
- unzip

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

## Adding App Types to Filestore

A script is provided in **app-scripts/setup_filestore_app.sh** (for dev)

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

**Note** the _nfs_store_all_access_ group owner can be changed to another owner, such as _nfs_store_group_0_ if access is to be controlled by the OS and user role _nfs_store group 600_
