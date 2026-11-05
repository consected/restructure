# Filestore Setup

Filestore is a component that provides upload, management and download of medical and project files.

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

The scheduled [filestore setup script](../app-scripts/set_up_missing_nfs_dirs.sh)
stops on the first setup failure, returns an error, and retains
`tmp/nfs_apps_list.txt` for the next retry without restarting the app server.
Directories and permission changes already made are not rolled back. Resolve
the reported error before retrying, and avoid restarting the app first: startup
regenerates the list using directory existence and could mark a partially
configured app type as complete.

While it runs, the scheduled script moves the list to
`tmp/nfs_apps_list.txt.processing` and holds a lock on
`tmp/nfs_apps_list.lock`, so overlapping runs exit without doing anything. The
app writes each new list to a temporary file and renames it into place, so a
list written by an app boot during a run is never read half-written or archived
unprocessed; it is processed on the next run, and on failure it takes priority
over the list being retried. A working list left by an interrupted run is
recovered on the next run unless a newer list has been written.

Each list entry ends with the containers path the app checks. After setting up
an app type, the scheduled script confirms that path exists, and otherwise fails
the same way, so a `MOUNTPOINT` or `SUBDIR` mismatch is reported rather than
causing repeated restarts. The app server is restarted only if an app type's
directories, ownership or permissions were actually changed. If everything was
already set up (for example by running `setup_filestore_app.sh` manually), the
list is archived without a restart, and admin configuration alerts remain
until the next restart.

When run directly, `setup_filestore_app.sh` exits 0 on success, including when
nothing needed to change. Set `UNCHANGED_EXIT_CODE` (1-255) to get that status
instead when nothing was changed.

**Note** the _nfs_store_all_access_ group owner can be changed to another owner, such as _nfs_store_group_0_ if access is to be controlled by the OS and user role _nfs_store group 600_
