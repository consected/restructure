#!/bin/bash

# Seed the AWS production or staging database by running the current version locally against the remote database
# Change the security group entry to allow access from your own IP address
# https://console.aws.amazon.com/ec2/v2/home

echo "Seed a database by running the current version locally against the remote database"
echo "======================================================================================================"
echo "Enter the DB host name"
read DB_HOST
echo
echo "Enter the DB name"
read DB_NAME
echo
echo "Enter the DB username"
read DB_USER
echo
echo "Enter password for the user"
read -s -p "$DB_USER user password: " TEMP_DB_PW
echo

FPHS_POSTGRESQL_HOSTNAME=$DB_HOST \
FPHS_POSTGRESQL_DATABASE=$DB_NAME \
RAILS_ENV=production \
FPHS_POSTGRESQL_SCHEMA=ml_app \
FPHS_POSTGRESQL_USERNAME=$DB_USER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_RAILS_SECRET_KEY_BASE=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_RAILS_DEVISE_SECRET_KEY=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_POSTGRESQL_PASSWORD="$TEMP_DB_PW" \
FPHS_LOAD_APP_TYPES=1 \
rake db:seed
