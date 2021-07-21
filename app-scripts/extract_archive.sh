#!/usr/bin/env bash
# Handle the unzip and validation of an nfs_store archive

archive_path=$1
tmpzipdir=$2

if [ -z "${archive_path}" ] || [ -z "${tmpzipdir}" ]; then
  echo >&2 "Requires two args"
  exit 3
fi

single_zip_path=$(mktemp /tmp/nfs-store-unzip-single-XXXXXXX)
tmpres=$(mktemp /tmp/nfs-store-unzip-res-XXXXXXX)

rm -f ${single_zip_path}
cd "$(dirname "${archive_path}")"

# Join split files to a single file in the temp directory
zip -q -s 0 "${archive_path}" -O "${single_zip_path}"
if [ $? != 0 ]; then
  rm -f "${single_zip_path}"
  echo >&2 "Failed zip -q -s 0 '${archive_path}' -O '${single_zip_path}'"
  exit 7
fi

unzip -n "${single_zip_path}" -d "${tmpzipdir}" > "${tmpres}"

if [ $? != 0 ]; then
  rm -f "${tempres}"
  rm -f "${single_zip_path}"

  echo >&2 "Failed unzip -n '${archive_path}' -d '${tmpzipdir}'"
  exit 1
fi

resnum=$(grep -E '(inflating|extracting):' "${tmpres}" | wc -l)
filecount=$(find "${tmpzipdir}" -type f | wc -l)
rm -f "${tempres}"
rm -f "${single_zip_path}"

if [ "${resnum}" != "${filecount}" ]; then
  echo >&2 "${resnum}" != "${filecount}"
  exit 2
fi

exit 0
