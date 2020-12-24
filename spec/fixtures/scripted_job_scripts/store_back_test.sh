#!/bin/bash

if [ ! "$1" ]; then
  echo 'First argument - file path - must be set'
  exit 3
fi

fpath=/tmp/rspec-test-script-handler

rm -rf $fpath
mkdir -p $fpath

echo 'loads of data' > "$fpath/newfile1.txt"
echo 'other data' > "$fpath/newfile2.txt"

echo "$fpath/newfile1.txt"
echo "$fpath/newfile2.txt"
