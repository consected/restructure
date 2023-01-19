#!/bin/bash
# Set up a dev filestore mount of a simulated external (NFS) filesystem,
# to allow full testing of a filestore environment on a self contained development machine.
# After running this script, run `.setup-dev-filestore.sh`

which bindfs
if [ $? != 0 ]; then
  echo "bindfs is not installed. Please install it before continuing"
  exit 1
fi

FS_TEST_BASE=${FS_TEST_BASE:=/home/$USER}

mkdir -p ${FS_TEST_BASE}/dev-file-source
mkdir -p ${FS_TEST_BASE}/dev-filestore
mkdir -p ${FS_TEST_BASE}/dev-bind-fs

function is_mountpoint() {
  if [ "$(which mountpoint)" ]; then
    mountpoint -q $1
  elif [ "$(which diskutil)" ]; then
    diskutil info "$1" > /dev/null
  else
    echo "Either mountpoint (Linux) or diskutil (macOS) must be installed"
    exit 7
  fi
}

bindfs -n ${FS_TEST_BASE}/dev-file-source ${FS_TEST_BASE}/dev-filestore
is_mountpoint ${FS_TEST_BASE}/dev-filestore
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
