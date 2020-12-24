#!/bin/bash

if [ "$1" == 'first' ] && [ "$2" == '/a/madeup/path' ] && [ "$3" == 'third' ]; then
  exit 0
else
  exit 1
fi
