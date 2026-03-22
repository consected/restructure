#!/bin/bash

DBNAME=${DBNAME:=restructure_demo}
DBOWNER=${DBOWNER:=restradmin}
DBAPP=${DBAPP:=restrapp}
SCHEMA_NAME=ml_app

read -p "Enter DB host name: " DBHOST
read -s -p "Enter password for new DB user ${DBOWNER}: " PWadmin
echo
read -s -p "Enter password for new DB user ${DBAPP}: " PWapp
echo

cd $(dirname $0)
echo "Current directory $(pwd)"
unzip ../db/demo-data.zip

psql -h $DBHOST -U postgres <<EOF
  create role ${DBOWNER};
  ALTER ROLE ${DBOWNER} WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN ;
  CREATE ROLE ${DBAPP};
  ALTER ROLE ${DBAPP} WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN;
  alter user ${DBOWNER} password '${PWadmin}';
  alter user ${DBAPP} password '${PWapp}';
  grant ${DBOWNER} to postgres;
  create database ${DBNAME} with owner ${DBOWNER};
  \c ${DBNAME};
  create schema $SCHEMA_NAME authorization ${DBOWNER};
  
  set role ${DBOWNER};

  \i ../db/structure.sql
  \i demo-data.sql
  GRANT USAGE ON SCHEMA $SCHEMA_NAME TO $DBAPP;
  GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA $SCHEMA_NAME TO $DBAPP;
  GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA_NAME TO $DBAPP;
EOF

# rm demo-data.sql

psql -h $DBHOST -U ${DBOWNER} -d $DBNAME <<EOF
EOF


FPHS_POSTGRESQL_HOSTNAME=$DBHOST \
FPHS_POSTGRESQL_DATABASE=$DBNAME \
RAILS_ENV=production \
FPHS_POSTGRESQL_SCHEMA=${SCHEMA_NAME} \
FPHS_POSTGRESQL_USERNAME=$DBOWNER \
FPHS_POSTGRESQL_PORT=5432 \
SECRET_KEY_BASE=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_RAILS_DEVISE_SECRET_KEY=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_POSTGRESQL_PASSWORD="${PWadmin}" \
bundle exec rake db:migrate