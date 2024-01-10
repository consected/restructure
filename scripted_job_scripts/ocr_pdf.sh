#!/bin/bash
# ocr_pdf.sh <PDF filename> <optional filename suffix> <optional ocrmypdf arguments>
# Optional arguments are like something like "--deskew --clean"
#
# See the document (docs/dev_reference/samples/scripted_job_ocr_setup.md) for
# information on setting up the Activity Log to call this scripted job.
#

if [ ! "$1" ]; then
  echo 'First argument - file path - must be set' >&2
  exit 3
fi

fn=$1
suffix=${2:='--ocr'}
args=$3
if [ -f "${fn}" ]; then
  new_dir=$(mktemp -d /tmp/nfs-store-ocr-XXXXXXX)
  new_fn="$(basename "${fn}")"
  new_fn="${new_fn/.pdf/${suffix}.pdf}"
  new_fn="${new_dir}/${new_fn}"
  ocrmypdf ${args} "${fn}" "${new_fn}" > /dev/null

  err=$?
  if [ ${err} == 0 ]; then
    echo "${new_fn}"
  else
    echo "Failed to run ocrmypdf. Error code: ${err}" >&2
    exit 4
  fi
else
  echo "File to ocr does not exist ${fn}" >&2
  exit 2
fi
