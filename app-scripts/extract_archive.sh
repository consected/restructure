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
tmpres=$(mktemp /tmp/nfs-store-unzip-res-XXXXXXX)
archive_fn="$(basename "${archive_path}")"

rm -f ${single_zip_path}
cd "$(dirname "${archive_path}")"

if [ "$(echo "${archive_path}" | grep -E '\.tar\.gz$')" ]; then

  tar -xvzf "${archive_path}" -C "${tmpzipdir}" > "${tmpres}"
  if [ $? != 0 ]; then
    rm -f "${tempres}"
    rm -f "${single_zip_path}"

    echo >&2 "Failed tar -xvzf '${archive_path}' -C '${tmpzipdir}'"
    cd ${currdir}
    exit 1
  fi

  # Add a single entry to the tar results to allow a simple comparison with what we find
  # in the extract directory
  echo '.' >> ${tmpres}
  resnum=$(cat "${tmpres}" | wc -l)
  filecount=$(find "${tmpzipdir}" | wc -l)

  rm -f "${tempres}"
  rm -f "${single_zip_path}"

  if [ "${resnum}" != "${filecount}" ]; then
    echo >&2 "${resnum}" != "${filecount}"
    cd ${currdir}
    exit 2
  fi
elif [ "$(echo "${archive_path}" | grep -E '\.zip$')" ]; then

  # Join split files to a single file in the temp directory
  # We send a 'q' to stdin just in case there is a prompt for a missing split file,
  # which seems to force an infinite loop
  zip -q -s 0 "${archive_fn}" -O "${single_zip_path}" << EOF
q
EOF

  if [ $? != 0 ]; then
    rm -f "${single_zip_path}"
    echo >&2 "Failed zip -q -s 0 '${archive_fn}' -O '${single_zip_path}' ---- in $(pwd)"
    cd ${currdir}
    exit 7
  fi

  unzip -n "${single_zip_path}" -d "${tmpzipdir}" > "${tmpres}"

  if [ $? != 0 ]; then
    rm -f "${tempres}"
    rm -f "${single_zip_path}"

    echo >&2 "Failed unzip -n '${archive_path}' -d '${tmpzipdir}'"
    cd ${currdir}
    exit 1
  fi

  resnum=$(grep -E '(inflating|extracting):' "${tmpres}" | wc -l)
  filecount=$(find "${tmpzipdir}" -type f | wc -l)
  rm -f "${tempres}"
  rm -f "${single_zip_path}"

  if [ "${resnum}" != "${filecount}" ]; then
    echo >&2 "${resnum}" != "${filecount}"
    cd ${currdir}
    exit 2
  fi
else
  echo >&2 "No decompressor for ${archive_path}"
  exit 10
fi

cd ${currdir}
exit 0
