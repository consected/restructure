----
# Create a local copy of the instance's schema, clean and empty
# Also get the list of schema migrations that the database believes it has seen completed
# One time only

#export EXTNAME=nfl-15.dipr.partners.org
export EXTNAME=nfl-16.dipr.partners.org
export EXTUSER=pda11
export DEVDIR=~/NetBeansProjects/fpa-phase2
export SCHEMA=ml_app

ssh $EXTUSER@$EXTNAME

sudo -u passenger -i

SCHEMA=ml_app
DB=q1
#DBHOST=nfl-09.dipr.partners.org
DBHOST=nfl-10.dipr.partners.org
cd /var/opt/passenger/fphs/db/dumps
mkdir migrate-`hostname`
cd migrate-`hostname`
pg_dump -d $DB -h $DBHOST --clean --create --schema-only --schema=$SCHEMA > "db-schema.sql"
# enter password
pg_dump -d $DB -h $DBHOST --data-only --schema=$SCHEMA --table=$SCHEMA.schema_migrations > "db-schema-migrations.sql"
#enter password
exit
exit



----- locally
DBUSER=`whoami`

cd $DEVDIR/db/dumps

ls -1 ../migrate/  | grep -oP '([0-9]+)' > migration-list.txt

VER=`date +%s`

mkdir migrate-$EXTNAME-$VER
cd migrate-$EXTNAME-$VER

# Get the files from the server
rsync $EXTUSER@$EXTNAME:/var/opt/passenger/fphs/db/dumps/migrate-$EXTNAME/db-schema* .
##### enter password

sudo -u postgres createdb -O $DBUSER mig_$VER
##### enter password
sudo -u postgres psql -d mig_$VER -c "create role fphs; create role fphsadm; create role fphsusr;"
psql -d mig_$VER < db-schema.sql
psql -d mig_$VER < db-schema-migrations.sql


psql -d mig_$VER -c "select * from ml_app.schema_migrations order by version" | grep -oP '([0-9]{10,20})' > mig_comp.txt
diff mig_comp.txt ../migration-list.txt |grep -oP '(> [0-9]{10,20})' | grep -oP '([0-9]{10,20})' > to_add.txt

#### Review the migration records to be added to the database to bring the schema_migrations table up to date


echo 'SET statement_timeout = 0;'  > db-schema-migrations-local.sql
echo 'SET lock_timeout = 0;' >> db-schema-migrations-local.sql
echo 'SET client_encoding = 'UTF8';'  >> db-schema-migrations-local.sql
echo 'SET standard_conforming_strings = on;'  >> db-schema-migrations-local.sql
echo 'SET check_function_bodies = false;'  >> db-schema-migrations-local.sql
echo 'SET client_min_messages = warning;'  >> db-schema-migrations-local.sql
echo "SET search_path = $SCHEMA, pg_catalog;"  >> db-schema-migrations-local.sql
echo 'COPY schema_migrations (version) FROM stdin;' >> db-schema-migrations-local.sql
cat to_add.txt >> db-schema-migrations-local.sql
echo '\.' >> db-schema-migrations-local.sql

psql -d mig_$VER < db-schema-migrations-local.sql

echo enter database password for $DBUSER
read password


FPHS_ADMIN_SETUP=yes \
FPHS_POSTGRESQL_PASSWORD=$password \
FPHS_POSTGRESQL_DATABASE=mig_$VER \
FPHS_POSTGRESQL_USERNAME=$DBUSER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_POSTGRESQL_HOSTNAME=localhost \
FPHS_POSTGRESQL_SCHEMA=$SCHEMA \
FPHS_RAILS_SECRET_KEY_BASE=A1111111111111111111111 \
FPHS_RAILS_DEVISE_SECRET_KEY=B2222222222222222222222 \
RAILS_ENV=production \
rake db:migrate:with_sql 

##### FIRST TIME when it fails - then repeat migrations
FPHS_POSTGRESQL_PASSWORD=$password \
FPHS_POSTGRESQL_DATABASE=mig_$VER \
FPHS_POSTGRESQL_USERNAME=$DBUSER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_POSTGRESQL_HOSTNAME=localhost \
FPHS_POSTGRESQL_SCHEMA=$SCHEMA \
FPHS_RAILS_SECRET_KEY_BASE=A1111111111111111111111 \
FPHS_RAILS_DEVISE_SECRET_KEY=B2222222222222222222222 \
RAILS_ENV=production \
rake db:seed
################

 

