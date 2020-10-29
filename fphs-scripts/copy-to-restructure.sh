#!/bin/bash

cd $(dirname ${$0})/..



for FROM in app bin config db/migrate db/seeds db/table_generators; do
  mkdir -p ${DEST}/${FROM}
  cp -u -r ${FROM} ${DEST}
done

for FROM in db/schema.rb db/seeds.rb db/structure.sql; do
  cp -u ${FROM} ${DEST}
done