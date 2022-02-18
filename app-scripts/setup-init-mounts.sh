#!/bin/bash
# Set up a dev filestore mount of a simulated external (NFS) filesystem,
# to allow full testing of a filestore environment on a self contained development machine.
# After running this script, run `.setup-dev-filestore.sh`

which bindfs
if [ $? != 0 ]; then
  echo "bindfs is not installed. Please install it before continuing"
  exit 1
fi

mkdir -p /home/$USER/dev-file-source
mkdir -p /home/$USER/dev-filestore
mkdir -p /home/$USER/dev-bind-fs

bindfs -n /home/$USER/dev-file-source /home/$USER/dev-filestore
mountpoint -q /home/$USER/dev-filestore
if [ $? != 0 ]; then
  echo "A mount was not successfully set up"
  exit 2
fi

cat << EOF
We have set up a dev filestore mount of a simulated external (NFS) filesystem:
  
  - /home/$USER/dev-file-source simulates an external (NFS) filesystem.
  - /home/$USER/dev-filestore is the mountpoint the external filesystem is mounted on this machine
  - /home/$USER/dev-bind-fs is the mountpoint for multiple OS group specific binds to be made

EOF
