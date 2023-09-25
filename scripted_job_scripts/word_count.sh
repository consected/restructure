#!/bin/bash

if [ ! "$1" ]; then
  echo 'First argument - file path - must be set'
  exit 3
fi

if [ -f "$1" ]; then
  dirname=$(mktemp -d)
  fn="${dirname}/$1--word-count.txt"
  wc "$1" > $fn
else
  exit 2
fi
