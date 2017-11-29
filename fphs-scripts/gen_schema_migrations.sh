#! /bin/bash
# ----
# Create a local copy of the instance's schema, clean and empty
# Also get the list of schema migrations that the database believes it has seen completed

# Requires that the user on the remote server has .pgpass created for the OS user to access the
# appropriate DB user


# Make sure we are running in the fphs-scripts directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


# get sudo setup to avoid unnecessary logins later
echo Enter your sudo password to allow us access to the local database postgres user
sudo pwd
clear

if [ -z "$1" ]
then

  echo Select which environment to generate
  echo '1 (pandora.catalyst)'
  echo '2 (vagrant-fphs-webapp-box)'
  echo '3 (not used)'
  echo '4 (fphs-webapp-dev01)'
  echo '5 (fphs-webapp-prod01)'

  read OPT

else
  OPT=$1

fi

if [ -z "$2" ]
then
  echo 'Enter your server username (openmed, vagrant or ecommons)'
  read ext_user
else
  ext_user=$2
fi



if [[ $OPT != '1' && $OPT != '2' && $OPT != '3' && $OPT != '4' && $OPT != '5' ]]
then
    echo Only 1, 2, 3, 4 or 5 are valid
    exit
fi

export BECOME_USER=''

if [ $OPT == '1' ]
then
#### if local shared dev #####
export EXTNAME=pandora.catalyst
export EXTUSER=$ext_user
export SCHEMA=public
export EXTDB=fphs
export EXTDBHOST=localhost
export EXTDBUSER=fphs
export EXPORTSVR=$EXTNAME
export EXPORTLOC=/tmp
export EXTROLE=fphs
export EXTADMROLE=fphs
export SEND_TO_DB=y
##############################
fi

if [ $OPT == '2' ]
then
#### if local vagrant test #####
export EXTNAME=vagrant-fphs-webapp-box
export EXTUSER=$ext_user
export BECOME_USER=postgres
export SCHEMA=ml_app
export EXTDB=fphs
export EXTDBHOST=localhost
export EXTDBUSER=postgres
export EXPORTSVR=$EXTNAME
export EXPORTLOC=/tmp
export EXTROLE=fphs
export EXTADMROLE=fphs
export SEND_TO_DB=y
###############################
fi

if [ $OPT == '3' ]
then
#### if partners production #####
export EXTNAME=nfl-16.dipr.partners.org
export EXTUSER=$ext_user
export SCHEMA=ml_app
export EXTDB=q1
export EXTDBHOST=nfl-10.dipr
export EXTDBUSER=$ext_user
export EXPORTSVR=nfl-03.dipr
export EXPORTLOC=/FPHS/stage/sql
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
export SEND_TO_DB=n
###############################
fi


if [ $OPT == '4' ]
then
#### if HMS IT dev #####
export EXTNAME=fphs-crm-dev01
export EXTUSER=$ext_user
export SCHEMA=ml_app
export EXTDB=fphs
export EXTDBHOST=fphs-db-dev01
export EXTDBUSER=$ext_user
export EXPORTSVR=fphs-crm-dev01
export EXPORTLOC=/FPHS/data/db_migrations
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
export SEND_TO_DB=n
###############################
fi

if [ $OPT == '5' ]
then
#### if HMS IT production #####
export EXTNAME=fphs-crm-prod01
export EXTUSER=$ext_user
export SCHEMA=ml_app
export EXTDB=fphs
export EXTDBHOST=fphs-db-prod01
export EXTDBUSER=$ext_user
export EXPORTSVR=fphs-crm-prod01
export EXPORTLOC=/FPHS/data/db_migrations
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
export SEND_TO_DB=n
###############################
fi

export DEVDIR="$(dirname $DIR)"
export DBHOST=localhost
export DBUSER=fphs
export DBUSERPW=fphs
export VER=`cat $DEVDIR/version.txt`

if [ -z "$BECOME_USER" ]
then
  export BECOME_USER_CMD=""
else
  export BECOME_USER_CMD="sudo -u $BECOME_USER -i"
fi

echo Storing results to development directory: $DEVDIR

echo Prepare dump of current schema from the remote server $EXTNAME
ssh -T $EXTUSER@$EXTNAME <<EOF
$BECOME_USER_CMD
cd /tmp
mkdir -p migrate-$EXTNAME
cd migrate-$EXTNAME
pg_dump -O -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --clean --create --schema-only --schema=$SCHEMA -T $SCHEMA.jd_tmp  -x > "db-schema.sql"
pg_dump -O -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --data-only --schema=$SCHEMA --table=$SCHEMA.schema_migrations -x > "db-schema-migrations.sql"
chmod 777 .
chmod 755 *
echo Done dumping files to `pwd`
exit
EOF

echo Schema dump completed

cd $DEVDIR/db/dumps

sudo chmod 777 .

mkdir -p migrate-$EXTNAME-$VER
cd migrate-$EXTNAME-$VER

echo Preparing full db/migrate list of Rails files
ls -1 ../../migrate/  | grep -oP '([0-9]+)' > migration-list.txt
echo `wc -l migration-list.txt` files available as Rails migrations

echo Pull the db-schema files back locally using rsync
rsync $EXTUSER@$EXTNAME:/tmp/migrate-$EXTNAME/db-schema* .

echo Create the local database
CURRDIR=`pwd`
#avoid scary cd warnings
cd /tmp
sudo -u postgres dropdb mig_db
sudo -u postgres psql < $DEVDIR/fphs-sql/create_roles.sql
sudo -u postgres createdb -O $DBUSER mig_db
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE fphs to fphs; alter role fphs password '$DBUSERPW'"

touch ~/.pgpass
echo "localhost:5432:mig_db:$DBUSER:$DBUSERPW" >> ~/.pgpass
chmod 600 ~/.pgpass

cd $CURRDIR

sed -i 's/CREATE SCHEMA public/-- CREATE SCHEMA public/g' db-schema.sql
sed -i 's/COMMENT ON SCHEMA public/-- COMMENT ON SCHEMA public/g' db-schema.sql

echo Create the local schema from the remote schema
psql -d mig_db -U $DBUSER -h localhost < db-schema.sql
psql -d mig_db -U $DBUSER -h localhost < db-schema-migrations.sql


psql -d mig_db -U $DBUSER -h localhost -c "select * from $SCHEMA.schema_migrations order by version" | grep -oP '([0-9]{10,20})' > mig_comp.txt
diff mig_comp.txt migration-list.txt |grep -oP '(> [0-9]{10,20})' | grep -oP '([0-9]{10,20})' > to_add.txt


#### Review the migration records to be added to the database to bring the schema_migrations table up to date
echo These are the migrations that need to be applied to bring the database up to date
cat to_add.txt
#####

echo Preparing the SQL for update
echo "SET search_path = $SCHEMA, pg_catalog;"  > db-schema-migrations-local.sql
echo 'COPY schema_migrations (version) FROM stdin;' >> db-schema-migrations-local.sql
cat to_add.txt >> db-schema-migrations-local.sql
echo '\.' >> db-schema-migrations-local.sql


UPGRADE_FILE=upgrade.sql

export APPEND_SQL="
GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA $SCHEMA TO $EXTROLE;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA $SCHEMA TO $EXTADMROLE;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $EXTROLE;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $EXTADMROLE;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $EXTROLE;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $EXTADMROLE;
`cat ./db-schema-migrations-local.sql `
"

echo Running the rails migrations and dumping the SQL
FPHS_ADMIN_SETUP=yes \
FPHS_POSTGRESQL_DATABASE=mig_db \
FPHS_POSTGRESQL_PASSWORD=$DBUSERPW \
FPHS_POSTGRESQL_USERNAME=$DBUSER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_POSTGRESQL_HOSTNAME=localhost \
FPHS_POSTGRESQL_SCHEMA=$SCHEMA \
FPHS_RAILS_SECRET_KEY_BASE=A1111111111111111111111 \
FPHS_RAILS_DEVISE_SECRET_KEY=B2222222222222222222222 \
RAILS_ENV=production \
bundle exec rake db:migrate:to_sql




echo "Generated the migration file for $EXTNAME : $UPGRADE_FILE"

echo Push results to $EXPORTSVR:$EXPORTLOC/migrate-$EXTNAME/
export REMOTE_UPGRADE_FILE_PATH=$EXPORTLOC/migrate-$EXTNAME/upgrade-$VER.sql
rsync $UPGRADE_FILE $EXTUSER@$EXPORTSVR:$REMOTE_UPGRADE_FILE_PATH


if [ "$SEND_TO_DB" == 'y' ]
then
###### Send the schema_migrations list back to

###### Now go to the remote machine and run the updates

ssh -T  $EXTUSER@$EXTNAME <<EOF
chmod 777 $EXPORTLOC/migrate-$EXTNAME/upgrade-$VER.sql
$BECOME_USER_CMD
cd $EXPORTLOC/migrate-$EXTNAME/
if [ "$EXTDBUSER"="$BECOME_USER" ]
then
  psql -d $EXTDB < $REMOTE_UPGRADE_FILE_PATH
else
  psql -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER < $REMOTE_UPGRADE_FILE_PATH
fi
exit
EOF

touch 'complete'
fi
