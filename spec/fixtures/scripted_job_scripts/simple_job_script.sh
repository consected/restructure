#!/bin/bash

if [ ! "$1" ]; then
  echo 'First argument - file path - must be set'
  exit 3
fi

if [ -f "$1" ]; then
  if [ ! "$(grep 'This is new content for the file' "$1")" ]; then
    echo "This is new content for the file" > "$1"
  else
    echo "This is other content for the file" > "$1"
  fi
else
  exit 2
fi
