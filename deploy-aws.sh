export INTERACTIVE_EB_INIT=--interactive
export EBAPPNAME=file-uploads
export EBENV=file-upload-dev
export EBREGION=us-east-1
export AWS_EB_PROFILE=fphsuser
export EB_PLATFORM="64bit Amazon Linux 2018.03 v2.8.0 running Ruby 2.4 (Passenger Standalone)"
export EB_KEYNAME=fphs-aws-eb

export SECRET_KEY_BASE=33391e5237bb2cc577fea6f8c918f88c525a5ce5b67d2c63ee59a83a5a6608eceb1429c66f3f739fd6b5855a5358be1a925acf92576707122228df06ef48b5a9
export DEVISE_SECRET_KEY_BASE=6af4b591e5bae2767923c576d447b9bcbd13fb86f15555dd092a46cee603b3d0efd9834668800007a72875270d78cbf46e940e78cdb54c96ea173eef8d19e82d

export DB_PASSWORD=grownPelicanOrangeHeptathalon
export DB_USERNAME=fphs
export DB_HOST=aaefcispocyk5n.c9dljdsduksr.us-east-1.rds.amazonaws.com

# echo Building nfs_store gem
# cd ../nfs_store
# ./build.sh
# git add .
# git commit -a -m "New release"
# cd -

echo Bundling
bundle install --no-deployment
rm -rf vendor/cache
bundle install --deployment
bundle package --all

echo Building assets
rake assets:clobber
rake assets:precompile
fphs-scripts/upversion.rb
git add .

echo Commit the changes
git commit -a -m "Build for deployment"

echo Ready to deploy? Hit enter to continue
read _

echo Init EB
eb init $EBAPPNAME -r $EBREGION --profile $AWS_EB_PROFILE $INTERACTIVE_EB_INIT -p "$EB_PLATFORM" -k "$EB_KEYNAME"
if [ "$CREATE_ENV" == 'true' ]
then
  eb create $EBENV -db.engine postgres --single --database.username $DB_USERNAME --database.password $DB_PASSWORD
fi
echo Use environment $EBENV
eb use $EBENV

echo Set environment variables


eb setenv \
SECRET_KEY_BASE="$SECRET_KEY_BASE" \
FPHS_RAILS_SECRET_KEY_BASE="$SECRET_KEY_BASE" \
FPHS_RAILS_DEVISE_SECRET_KEY="$DEVISE_SECRET_KEY_BASE" \
RAILS_ENV=production \
RAILS_SERVE_STATIC_FILES=false \
RAILS_SKIP_ASSET_COMPILATION=false \
RAILS_SKIP_MIGRATIONS=false \
FILESTORE_CONTAINERS_DIRNAME=containers \
FILESTORE_NFS_DIR=/mnt/fphsfs \
FILESTORE_TEMP_UPLOADS_DIR=/tmp/uploads \
RDS_SCHEMA="ipa_ops,ml_app,persnet" \
RDS_HOSTNAME="$DB_HOST" \
RDS_PORT=5432 \
RDS_USERNAME="$DB_USERNAME" \
RDS_PASSWORD="$DB_PASSWORD" \
RDS_DB_NAME=ebdb \
FPHS_POSTGRESQL_HOSTNAME="$DB_HOST" \
FPHS_POSTGRESQL_USERNAME="$DB_USERNAME" \
FPHS_POSTGRESQL_PASSWORD="$DB_PASSWORD" \
FPHS_POSTGRESQL_DATABASE=ebdb \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_POSTGRESQL_SCHEMA="ipa_ops,ml_app,persnet" \
FPHS_X_SENDFILE_HEADER="X-Accel-Redirect"


eb deploy $EBENV
