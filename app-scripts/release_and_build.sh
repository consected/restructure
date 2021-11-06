#!/bin/bash

echo "Starting release and build"
CURRDIR="$(pwd)"

export GIT_MERGE_AUTOEDIT=no

ONDEVELOP="$(git branch | grep '* develop')"
if [ -z "${ONDEVELOP}" ]; then
  echo "Must be on develop branch to get started"
  exit 1
fi

GITSTATUS="$(git status --porcelain=1)"
if [ ! -z "${GITSTATUS}" ]; then
  echo "No files must be uncommitted"
  git status
  exit 1
fi

git pull

cl_not_ok=$(grep -Pzl '## Unreleased\n+##' CHANGELOG.md)
if [ "${cl_not_ok}" ]; then
  echo "CHANGELOG.md does not have anything entered for the Unreleased section. Edit and retry."
  exit 2
fi

echo "Clean up assets before we start"
FPHS_LOAD_APP_TYPES=1 bundle exec rake assets:clobber
git commit public/assets -m "Cleanup"
git push

GENVERFILE=shared/build_version.txt
CURRVERFILE=version.txt
ALLTAGS="$(git tag --sort=-taggerdate)"
CURRVER=$(cat ${CURRVERFILE})
NEWVER="$(VERSION_FILE=${CURRVERFILE} app-scripts/upversion.rb -p)"
RELEASESTARTED="$(echo ${ALLTAGS} | grep ${NEWVER})"

echo "Current version: ${CURRVER}"
echo "Next version: ${NEWVER}"

source ../restructure-build/shared/build-vars.sh
if [ "$(cat .ruby-version)" != ${RUBY_V} ]; then
  echo "Ruby versions don't match: $(cat .ruby-version) != ${RUBY_V}"
  exit 7
fi

if [ -z "${SKIP_BRAKEMAN}" ]; then
  echo "Checking brakeman before we go through the whole process"
  bin/brakeman -q --summary > /tmp/fphs-brakeman-summary.txt
  if [ "$?" == 0 ]; then
    echo "Brakeman OK"
  else
    cat /tmp/fphs-brakeman-summary.txt
    echo "Brakeman Failed"
    exit 1
  fi
fi

if [ -z "${RELEASESTARTED}" ]; then
  echo "Starting git-flow release"
  git flow release start ${NEWVER}
  RES=$?
  if [ "$RES" != "0" ]; then
    echo $RES
    exit
  fi
  git push --set-upstream origin release/${NEWVER}
  git flow release finish -m 'Release' ${NEWVER}
else
  echo "Release already started. Checking out and continuing"
  git checkout new-master && git pull && git merge develop
fi
git push origin --tags
git push origin --all

git checkout develop

echo "Starting build container"
cd ../restructure-build
./build.sh
if [ $? != 0 ]; then
  echo "***** build.sh failed with exit code $? *****"
  exit 101
fi

if [ ! -s ${GENVERFILE} ]; then
  echo "${GENVERFILE} in $(pwd) was not set. The build was not successful"
  exit 1
fi

TESTVER=$(cat ${GENVERFILE})

if [ "${TESTVER}" == "${CURRVER}" ] || [ ! "${TESTVER}" ]; then
  echo "Build failed"
  echo "'${TESTVER}' == '${CURRVER}'"
  exit 1
else
  echo "Build successful"
fi

cd ${CURRDIR}
git fetch origin
git checkout new-master
git pull
git checkout develop
git pull
git merge new-master
git push
echo "Built and setup assets: ${TESTVER}"
