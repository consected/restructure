#!/usr/bin/env bash
# Handle the unzip and validation of an nfs_store archive

archive_path=$1
tmpzipdir=$2

if [ -z "${archive_path}" ] || [ -z "${tmpzipdir}" ]; then
  echo >&2 "Requires two args"
  exit 3
fi

tmpres=/tmp/$(mktemp nfs-store-unzipresXXXXXXX)
unzip -n "${archive_path}" -d "${tmpzipdir}" > "${tmpres}"

if [ $? != 0 ]; then
  rm -f ${tempres}
  echo >&2 "Failed unzip -n '${archive_path}' -d '${tmpzipdir}'"
  exit 1
fi

resnum=$(grep -E '(inflating|extracting):' "${tmpres}" | wc -l)
filecount=$(find "${tmpzipdir}" -type f | wc -l)
rm -f "${tempres}"

if [ "${resnum}" != "${filecount}" ]; then
  echo >&2 "${resnum}" != "${filecount}"
  exit 2
fi

exit 0
