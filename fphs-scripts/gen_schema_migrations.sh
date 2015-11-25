----
# Create a local copy of the instance's schema, clean and empty
# Also get the list of schema migrations that the database believes it has seen completed


# get sudo setup to avoid unnecessary logins later
sudo pwd


#### if local shared dev #####
export EXTNAME=pandora.catalyst
export EXTUSER=payres
export SCHEMA=public
export EXTDB=fphs
export EXTDBHOST=localhost
export EXTDBUSER=phil
##############################

#### if stage #####
export EXTNAME=nfl-15.dipr.partners.org
export EXTUSER=pda11
export SCHEMA=ml_app
export EXTDB=q1
export EXTDBHOST=nfl-09.dipr
export EXTDBUSER=pda11
###############################

#### if production #####
export EXTNAME=nfl-16.dipr.partners.org
export EXTUSER=pda11
export SCHEMA=ml_app
export EXTDB=q1
export EXTDBHOST=nfl-10.dipr
export EXTDBUSER=pda11
###############################


export DEVDIR=~/NetBeansProjects/fpa-phase3
export DBHOST=localhost
export DBUSER=`whoami`
export VER=`date +%s`



ssh $EXTUSER@$EXTNAME <<EOF
cd /var/opt/passenger/fphs/db/dumps
mkdir -p migrate-$EXTNAME
cd migrate-$EXTNAME
pg_dump -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --clean --create --schema-only --schema=$SCHEMA -T $SCHEMA.jd_tmp  -x > "db-schema.sql"
pg_dump -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER --data-only --schema=$SCHEMA --table=$SCHEMA.schema_migrations -x > "db-schema-migrations.sql"
exit
EOF

----- locally


cd $DEVDIR/db/dumps

ls -1 ../migrate/  | grep -oP '([0-9]+)' > migration-list.txt

mkdir -p migrate-$EXTNAME-$VER
cd migrate-$EXTNAME-$VER


rsync $EXTUSER@$EXTNAME:/var/opt/passenger/fphs/db/dumps/migrate-$EXTNAME/db-schema* .
##### enter password

sudo -u postgres dropdb mig_$VER
sudo -u postgres createdb -O $DBUSER mig_$VER
##### enter password
sudo -u postgres psql -d mig_$VER -c "create role fphs; create role fphsadm; create role fphsusr;"
psql -d mig_$VER < db-schema.sql
psql -d mig_$VER < db-schema-migrations.sql


psql -d mig_$VER -c "select * from $SCHEMA.schema_migrations order by version" | grep -oP '([0-9]{10,20})' > mig_comp.txt
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


echo enter database password for $DBUSER
read password


UPGRADE_FILE=upgrade-$EXTNAME-$VER.sql

export APPEND_SQL="
GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ML_APP TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ML_APP TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSADM;
`cat ./db-schema-migrations-local.sql `
"

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




echo "Generated the migration file for $EXTNAME"

###### Send the schema_migrations list back to 
rsync ./db-schema-migrations-local.sql $EXTUSER@$EXTNAME:/var/opt/passenger/fphs/db/dumps/migrate-$EXTNAME/
rsync ../$UPGRADE_FILE $EXTUSER@$EXTNAME:/var/opt/passenger/fphs/db/dumps/migrate-$EXTNAME/

###### Now go to the remote machine and run the updates

ssh $EXTUSER@$EXTNAME <<EOF
cd /var/opt/passenger/fphs/db/dumps/migrate-$EXTNAME/
psql -d $EXTDB -h $EXTDBHOST -U $EXTDBUSER < $UPGRADE_FILE
exit
EOF
