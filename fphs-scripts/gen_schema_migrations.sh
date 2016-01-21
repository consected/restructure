#! /bin/bash
# ----
# Create a local copy of the instance's schema, clean and empty
# Also get the list of schema migrations that the database believes it has seen completed

# Make sure we are running in the fphs-scripts directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


# get sudo setup to avoid unnecessary logins later
echo Enter your sudo password
sudo pwd
clear

echo Select which environment to generate
echo '1 (pandora.catalyst)'
echo '2 (nfl-09 Stage)'
echo '3 (nfl-10 Production)'
read OPT

if [[ $OPT != '1' && $OPT != '2' && $OPT != '3' ]] 
then
    echo Only 1, 2 or 3 are valid
    exit
fi

if [ $OPT == '1' ] 
then
#### if local shared dev #####
export EXTNAME=pandora.catalyst
export EXTUSER=payres
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
#### if stage #####
export EXTNAME=nfl-15.dipr.partners.org
export EXTUSER=pda11
export SCHEMA=ml_app
export EXTDB=q1
export EXTDBHOST=nfl-09.dipr
export EXTDBUSER=pda11
export EXPORTSVR=nfl-03.dipr
export EXPORTLOC=/FPHS/stage/sql
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
export SEND_TO_DB=n
###############################
fi

if [ $OPT == '3' ] 
then
#### if production #####
export EXTNAME=nfl-16.dipr.partners.org
export EXTUSER=pda11
export SCHEMA=ml_app
export EXTDB=q1
export EXTDBHOST=nfl-10.dipr
export EXTDBUSER=pda11
export EXPORTSVR=nfl-03.dipr
export EXPORTLOC=/FPHS/stage/sql
export EXTROLE=FPHSUSR
export EXTADMROLE=FPHSADM
export SEND_TO_DB=n
###############################
fi


export DEVDIR="$(dirname $DIR)"
export DBHOST=localhost
export DBUSER=`whoami`
export VER=`cat $DEVDIR/version.txt`

echo Storing results to development directory: $DEVDIR

echo Prepare dump of current schema from the remote server $EXTNAME
ssh -T $EXTUSER@$EXTNAME <<EOF
cd /tmp
mkdir -p migrate-$EXTNAME
cd migrate-$EXTNAME
pg_dump -O -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --clean --create --schema-only --schema=$SCHEMA -T $SCHEMA.jd_tmp  -x > "db-schema.sql"
pg_dump -O -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --data-only --schema=$SCHEMA --table=$SCHEMA.schema_migrations -x > "db-schema-migrations.sql"
echo Done dumping files to `pwd`
exit
EOF

echo Schema dump completed

cd $DEVDIR/db/dumps


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
sudo -u postgres createdb -O $DBUSER mig_db
sudo -u postgres psql -d mig_db < $DEVDIR/fphs-sql/create_roles.sql

cd $CURRDIR

sed -i 's/CREATE SCHEMA public/-- CREATE SCHEMA public/g' db-schema.sql
sed -i 's/COMMENT ON SCHEMA public/-- COMMENT ON SCHEMA public/g' db-schema.sql

echo Create the local schema from the remote schema
psql -d mig_db < db-schema.sql
psql -d mig_db < db-schema-migrations.sql


psql -d mig_db -c "select * from $SCHEMA.schema_migrations order by version" | grep -oP '([0-9]{10,20})' > mig_comp.txt
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
FPHS_POSTGRESQL_PASSWORD= \
FPHS_POSTGRESQL_USERNAME=$DBUSER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_POSTGRESQL_HOSTNAME= \
FPHS_POSTGRESQL_SCHEMA=$SCHEMA \
FPHS_RAILS_SECRET_KEY_BASE=A1111111111111111111111 \
FPHS_RAILS_DEVISE_SECRET_KEY=B2222222222222222222222 \
RAILS_ENV=production \
rake db:migrate:with_sql 




echo "Generated the migration file for $EXTNAME : $UPGRADE_FILE"

echo Push results to $EXPORTSVR:$EXPORTLOC/migrate-$EXTNAME/
rsync $UPGRADE_FILE $EXTUSER@$EXPORTSVR:$EXPORTLOC/migrate-$EXTNAME/upgrade-$VER.sql


if [ "$SEND_TO_DB" == 'y' ]
then
###### Send the schema_migrations list back to 

###### Now go to the remote machine and run the updates

ssh -T  $EXTUSER@$EXTNAME <<EOF
cd $EXPORTLOC/migrate-$EXTNAME/
psql -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER < $UPGRADE_FILE
exit
EOF

touch 'complete'
fi