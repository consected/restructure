#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: app-scripts/copy-to-restructure.sh <DESTINATION FOLDER>"
  echo "For example: app-scripts/copy-to-restructure.sh ../../restructure/restructure/"
  exit 1
fi

cd $(dirname $0)/..
STARTDIR=$(pwd)

DEST="$1"
if [ ! -d ${DEST} ]; then
  echo "Destination directory '${DEST}' does not exist"
  exit 2
fi

EXCLUDE='database.yml favicon.png app/assets/images/restructure-logo.svg initializers/app_default_settings.rb .git assets/stylesheets/app_vars.scss'

for e in ${EXCLUDE}; do
  EXCLUDES="${EXCLUDES} --exclude=${e}"
done

cd ${DEST}
git pull
if [ $? != 0 ]; then
  echo 'Failed to pull the destination repo.'
fi

cd ${STARTDIR}

if [ -d public/assets ]; then
  bundle exec rake assets:clobber
fi

for FROM in app bin config db/migrate db/seeds db/table_generators db/app_migrations/data_requests app-scripts/supporting \
  lib public/fonts public/app_specific/data_requests script spec \
  docs/admin_reference docs/user_reference docs/dev_reference docs/guest_reference docs/app_reference/zeus \
  vendor/assets/images vendor/assets/javascripts vendor/assets/stylesheets; do
  mkdir -p "${DEST}/${FROM}"
  echo "${FROM}"
  rsync -crv --delete ${EXCLUDES} "${FROM}/" "${DEST}/${FROM}"/
done

mkdir -p ${DEST}/docs
mkdir -p ${DEST}/db/dumps/development-data

for FROM in \
  yarn.lock package.json \
  docs/filestore-setup.md \
  db/seeds.rb \
  app-scripts/add_admin.sh app-scripts/api-get-container-id.sh app-scripts/parallel_test.sh \
  app-scripts/release_and_build.sh \
  app-scripts/setup_filestore_app.sh app-scripts/setup-dev-filestore.sh app-scripts/upload-to-filestore.sh \
  app-scripts/upversion.rb app-scripts/validate_file_signature.sh \ app-scripts/extract_archive.sh \
  public/.gitignore public/*.html public/robots.txt \
  public/app_specific/app_data_requests.css \
  .gitignore .rspec_parallel .rubocop.yml .ruby-version .solargraph.yml config.ru \
  Gemfile* Rakefile vendor/assets/config.json version.txt; do
  echo "${FROM}"
  cp -f "${FROM}" "${DEST}/${FROM}"
done

# Removed db/structure.sql

rm -rf ${DEST}/log
rm -rf ${DEST}/tmp

mkdir -p ${DEST}/log
mkdir -p ${DEST}/tmp

cd ${DEST}

grep --recursive harvard.edu *
grep --recursive partners.edu *
grep --recursive mgb.edu *
