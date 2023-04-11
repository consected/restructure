#!/usr/bin/env bash
# Handle the unzip and validation of an nfs_store archive

archive_path=$1
tmpzipdir=$2
currdir=$(pwd)
if [ -z "${archive_path}" ] || [ -z "${tmpzipdir}" ]; then
  echo >&2 "Requires two args"
  exit 3
fi

single_zip_path=$(mktemp /tmp/nfs-store-unzip-single-XXXXXXX)
tempres=$(mktemp /tmp/nfs-store-unzip-res-XXXXXXX)
archive_fn="$(basename "${archive_path}")"

rm -f "${single_zip_path}"
cd "$(dirname "${archive_path}")" || exit 1

# Join split files to a single file in the temp directory
# We send a 'q' to stdin just in case there is a prompt for a missing split file,
# which seems to force an infinite loop
zip -q -s 0 "${archive_fn}" -O "${single_zip_path}" << EOF
q
EOF

if [ $? != 0 ]; then
  rm -f "${single_zip_path}"
  echo >&2 "Failed zip -q -s 0 '${archive_fn}' -O '${single_zip_path}' ---- in $(pwd)"
  cd "${currdir}" || exit 7
  exit 7
fi

unzip -n "${single_zip_path}" -d "${tmpzipdir}" > "${tempres}"

if [ $? != 0 ]; then
  rm -f "${tempres}"
  rm -f "${single_zip_path}"

  echo >&2 "Failed unzip -n '${archive_path}' -d '${tmpzipdir}'"
  cd "${currdir}" || exit 1
  exit 1
fi

resnum=$(grep -E '(inflating|extracting):' "${tempres}" | wc -l)
filecount=$(find "${tmpzipdir}" -type f | wc -l)
rm -f "${tempres}"
rm -f "${single_zip_path}"

if [ "${resnum}" != "${filecount}" ]; then
  echo >&2 "${resnum}" != "${filecount}"
  cd "${currdir}" || exit 2
  exit 2
fi

cd "${currdir}"
exit 0
