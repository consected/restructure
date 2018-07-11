#! /bin/bash
# ----
# Create a local copy of the instance's schema, clean and empty
# Also get the list of schema migrations that the database believes it has seen completed

# Requires that the user on the remote server has .pgpass created for the OS user to access the
# appropriate DB user

# Optionally automatically push results to the target database by setting environment variable
# SEND_TO_DB=y ./gen_schema_migrations.sh

# Make sure we are running in the fphs-scripts directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


# get sudo setup to avoid unnecessary logins later
echo Enter your sudo password to allow us access to the local database postgres user
sudo pwd
clear

ext_user=$2


if [ -z "$1" ]
then

  echo Select which environment to generate
  echo '1 (localhost - using exported scripts to create a reference database)'
  echo '2 (vagrant-fphs-webapp-box - update vagrant test box from host)'
  echo '3 (test DBs fphs against fpa_development within vagrant dev box guest)'
  echo '4 (fphs-crm-dev01)'
  echo '5 (fphs-crm-dev02)'
  echo '6 (fphs-crm-prod01)'

  read OPT

else
  OPT=$1
fi

if [ $OPT == '1' ]
then
  ext_user=`whoami`
fi

if [ $OPT == '2' ]
then
  ext_user='vagrant'
fi

if [ $OPT == '3' ]
then
  ext_user='vagrant'
fi


if [ -z "$ext_user" ]
then
  echo 'Enter your server username (ecommons name)'
  read ext_user
fi



if [[ $OPT != '1' && $OPT != '2' && $OPT != '3' && $OPT != '4' && $OPT != '5' && $OPT != '6' ]]
then
    echo Only 1, 2, 3, 4, 5 or 6 are valid
    exit
fi

export BECOME_USER=''

if [ -z "$SEND_TO_DB" ]
then
  export SEND_TO_DB=n
fi

if [ $OPT == '1' ]
then
#### if local shared dev #####
export NOSSH=yes
export MAKEREFDB=yes
export EXTNAME=localhost
export EXTUSER=$ext_user
export BECOME_USER=postgres
export SCHEMA=ml_app
export EXTDB=fphs_offline_ref
export EXTDBHOST=localhost
export EXTDBUSER=fphs
export EXPORTSVR=$EXTNAME
export EXPORTLOC=/tmp
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM

echo This option creates a local reference database from a schema SQL definition previously exported from a remote database.
echo In addition, an export of the data from the table 'schema_migrations' is required.
echo To create these:
echo '  pg_dump -O -s -d db_name > "schema.sql"'
echo '  pg_dump -O -d db_name --data-only --schema=ml_app --table=ml_app.schema_migrations -x > "db-schema-migrations.sql"'
echo 'When ready to continue, press Enter'
read _ready
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
###############################
fi

if [ $OPT == '3' ]
then
#### if test DBs fphs against fpa_development within vagrant dev box guest #####
export EXTNAME=localhost
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
export EXTDBUSER=passenger
export EXPORTSVR=fphs-crm-dev01
export EXPORTLOC=/FPHS/share/db_migrations
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
###############################
fi



if [ $OPT == '5' ]
then
#### if HMS IT dev #####
export EXTNAME=fphs-crm-dev02
export EXTUSER=$ext_user
export SCHEMA=ml_app
export EXTDB=fphs
export EXTDBHOST=fphs-crm-dev02
export EXTDBUSER=fphs
export EXPORTSVR=fphs-crm-dev02
export EXPORTLOC=/tmp
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
###############################
fi

if [ $OPT == '6' ]
then
#### if HMS IT production #####
export EXTNAME=fphs-crm-prod01
export EXTUSER=$ext_user
export SCHEMA=ml_app
export EXTDB=fphs
export EXTDBHOST=fphs-db-prod01
export EXTDBUSER=passenger
export EXPORTSVR=fphs-crm-prod01
export EXPORTLOC=/FPHS/data/db_migrations
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
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
  export EXTDBCONN="-h $EXTDBHOST -U $EXTDBUSER"
  echo "NOTE: your ecommons user on the remote server requires a .pgpass entry for $EXTDBHOST:5432:$EXTDB:$EXTDBUSER:<password>"
else
  export BECOME_USER_CMD="sudo -u $BECOME_USER -i"
  export EXTDBCONN=''
fi

if [ -z "$NOSSH" ]
then
  export RUNSCRIPT="ssh -T $EXTUSER@$EXTNAME"
else
  export RUNSCRIPT="bash"
fi

echo Storing results to development directory: $DEVDIR

if [ "$MAKEREFDB" == 'yes' ]
then
  echo Create the local reference database
  CURRDIR=`pwd`
  #avoid scary cd warnings
  cd /tmp
  sudo -u postgres dropdb $EXTDB
  sudo -u postgres psql < $DEVDIR/fphs-sql/create_roles.sql
  sudo -u postgres createdb -O $DBUSER $EXTDB
  sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $EXTDB to fphs; alter role fphs password '$DBUSERPW'"

  touch ~/.pgpass
  echo "localhost:5432:$EXTDB:$DBUSER:$DBUSERPW" >> ~/.pgpass
  chmod 600 ~/.pgpass

  echo "Use '\i schema.sql' to import the database and migration files"
  sudo -u postgres psql -d $EXTDB

  cd $CURRDIR

fi



echo Prepare dump of current schema from the server $EXTNAME
$RUNSCRIPT <<EOF
cd /tmp
mv migrate-$EXTNAME migrate-$EXTNAME.old.`date --iso-8601=seconds`
cd -
echo become user? $BECOME_USER_CMD
$BECOME_USER_CMD
cd /tmp
mkdir -p migrate-$EXTNAME
cd migrate-$EXTNAME
echo -d $EXTDB $EXTDBCONN
pg_dump -O -d $EXTDB $EXTDBCONN --clean --create --schema-only --schema=$SCHEMA -T $SCHEMA.jd_tmp  -x > "db-schema.sql"
pg_dump -O -d $EXTDB $EXTDBCONN --data-only --schema=$SCHEMA --table=$SCHEMA.schema_migrations -x > "db-schema-migrations.sql"
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

if [ "$EXTNAME" == 'localhost' ]
then
  echo Copying the local db-schema files to the correct location
  cp /tmp/migrate-$EXTNAME/db-schema* .
else
  echo Pull the db-schema files back locally using rsync
  rsync $EXTUSER@$EXTNAME:/tmp/migrate-$EXTNAME/db-schema* .
fi

echo Create the local database
CURRDIR=`pwd`
#avoid scary cd warnings
cd /tmp
sudo -u postgres dropdb mig_db
sudo -u postgres psql < $DEVDIR/fphs-sql/create_roles.sql
sudo -u postgres createdb -O $DBUSER mig_db
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE mig_db to fphs; alter role fphs password '$DBUSERPW'"

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

echo Pushing results to $EXPORTSVR:$EXPORTLOC/migrate-$EXTNAME/
export REMOTE_UPGRADE_FILE_PATH=$EXPORTLOC/migrate-$EXTNAME/upgrade-$VER.sql
rsync $UPGRADE_FILE $EXTUSER@$EXPORTSVR:$REMOTE_UPGRADE_FILE_PATH


if [ "$SEND_TO_DB" == 'y' ]
then
###### Send the schema_migrations list back to

###### Now go to the remote machine and run the updates

$RUNSCRIPT <<EOF
chmod 777 $EXPORTLOC/migrate-$EXTNAME/upgrade-$VER.sql
$BECOME_USER_CMD
cd $EXPORTLOC/migrate-$EXTNAME/
psql -d $EXTDB $EXTDBCONN < $REMOTE_UPGRADE_FILE_PATH
exit
EOF
echo ===============
echo Pushed results to $EXPORTSVR:$EXPORTLOC/migrate-$EXTNAME/
echo ===============
touch 'complete'
fi
