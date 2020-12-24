#!/bin/bash

if [ "$1" == '1' ] && [ "$2" == 'user-1' ] && [ "$3" == 'third' ]; then
  echo "second arg was $2"
  exit 0
else
  exit 1
fi
