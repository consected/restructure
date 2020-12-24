#!/bin/bash

if [ "$1" == 'first' ] && [ "$2" == 'second' ] && [ "$3" == 'third' ]; then
  echo "args $1 $2 $3"
  exit 0
else
  exit 1
fi
