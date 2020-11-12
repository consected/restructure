#!/bin/bash
# Dump data only to support building a demo / development server
# Import the data before seeding the database to ensure a successful import

pg_dump \
  -O -x \
  -d fpa_development \
  --data-only \
  --schema=ml_app \
  -t ml_app.masters \
  -t ml_app.scantrons \
  -t ml_app.player_infos \
  -t ml_app.player_contacts \
  -t ml_app.addresses \
  -t ml_app.users \
  -t ml_app.admins \
  -t ml_app.app_types \
  -t ml_app.pro_infos \
  > /tmp/demo-data.sql
