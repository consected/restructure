#!/bin/bash
# Set up a dev filestore mount of a simulated external (NFS) filesystem,
# to allow full testing of a filestore environment on a self contained development machine.
# After running this script, run `.setup-dev-filestore.sh`

which bindfs

# shellcheck disable=SC2181
if [ $? != 0 ]; then
  echo "bindfs is not installed. Please install it before continuing"
  exit 1
fi

if ! [[ "$(which mountpoint)" || "$(which diskutil)" ]]; then
  echo "Either mountpoint (Linux) or diskutil (macOS) must be installed."
  exit 1;
fi

FS_TEST_BASE=${FS_TEST_BASE:=/home/$USER}

mkdir -p "${FS_TEST_BASE}"/dev-file-source
mkdir -p "${FS_TEST_BASE}"/dev-filestore
mkdir -p "${FS_TEST_BASE}"/dev-bind-fs

function is_mountpoint() {
  MOUNTED_VOLUME=$1
  if [ "$(which mountpoint)" ]; then
    mountpoint -q "$MOUNTED_VOLUME"
  elif [ "$(which diskutil)" ]; then
    echo "mounting... $MOUNTED_VOLUME"
    if [[ $(mount | awk -v MOUNTED_VOLUME="$MOUNTED_VOLUME" '$3 == MOUNTED_VOLUME  {print $3}') != "" ]]; then
      echo "$MOUNTED_VOLUME is mounted"
    else
      echo "$MOUNTED_VOLUME is NOT mounted"
      exit 7
    fi
  else
    echo "Either mountpoint (Linux) or diskutil (macOS) must be installed"
    exit 7
  fi
}

bindfs -n "${FS_TEST_BASE}"/dev-file-source "${FS_TEST_BASE}"/dev-filestore
is_mountpoint "${FS_TEST_BASE}"/dev-filestore

# shellcheck disable=SC2181
if [ $? != 0 ]; then
  echo "A mount was not successfully set up at: ${FS_TEST_BASE}/dev-filestore"
  exit 2
fi

cat << EOF
We have set up a dev filestore mount of a simulated external (NFS) filesystem:

  - ${FS_TEST_BASE}/dev-file-source simulates an external (NFS) filesystem.
  - ${FS_TEST_BASE}/dev-filestore is the mountpoint the external filesystem is mounted on this machine
  - ${FS_TEST_BASE}/dev-bind-fs is the mountpoint for multiple OS group specific binds to be made

EOF
