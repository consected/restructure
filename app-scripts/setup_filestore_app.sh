#!/bin/bash
# Setup a container for a new app type in the mounted NFS
#./setup_app_type.sh

APP_TYPE_ID=$1

if [ -z "$APP_TYPE_ID" ]; then
  echo "Call with argument <app_type_id>"
  read -p 'Enter app type ID: ' APP_TYPE_ID
fi

if [ -z "$MOUNTPOINT" ]; then
  if [ "$RAILS_ENV" == 'production' ]; then
    MOUNTPOINT=/efs1
  else
    MOUNTPOINT=/home/$USER/dev-filestore
    if [ ! -d ${MOUNTPOINT} ]; then
      echo "MOUNTPOINT ${MOUNTPOINT} does not exist. Where is it?"
      read -p 'MOUNTPOINT directory: ' MOUNTPOINT
    fi
  fi
fi

echo "Mountpoint is: $MOUNTPOINT"

if [ -z "${SUBDIR}" ]; then
  ls ${MOUNTPOINT}
  read -p 'Enter the selected directory: ' SUBDIR
fi

OWNER_GROUP=${OWNER_GROUP:='nfs_store_group_0'}

FS_ROOT=${MOUNTPOINT}/${SUBDIR}

if [ -d ${FS_ROOT}/main ]; then
  FS_DIR=main
fi
APPTYPE_DIR=app-type-${APP_TYPE_ID}

cd $FS_ROOT/$FS_DIR
mkdir -p $APPTYPE_DIR/containers

echo "become sudo to setup file ownership"
sudo echo "in: $APPTYPE_DIR/containers"

sudo chmod 770 $APPTYPE_DIR
sudo chmod 770 $APPTYPE_DIR/containers
sudo chown nfsuser:nfs_store_all_access $APPTYPE_DIR
sudo chown nfsuser:${OWNER_GROUP} $APPTYPE_DIR/containers
