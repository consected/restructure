#!/bin/bash
CURRDIR="$(pwd)"

ONDEVELOP="$(git branch | grep '* develop')"
if [ -z "${ONDEVELOP}" ]; then
  echo "Must be on develop branch to get started"
  exit 1
fi

if [ ! -z "${GITSTATUS}" ]; then
  echo "No files must be uncommitted"
  git status
  exit 1
fi

FPHS_LOAD_APP_TYPES=1 bundle exec rake assets:clobber
git commit public/assets -m "Cleanup"

GITSTATUS="$(git status --porcelain=1)"

git push

CURRVERFILE=shared/build_version.txt
ALLTAGS="$(git tag --sort=-taggerdate)"
CURRVER=$(cat ${CURRVERFILE})
NEWVER="$(VERSION_FILE=${CURRVERFILE} app-scripts/upversion.rb -p)"
RELEASESTARTED="$(echo ${ALLTAGS} | grep ${NEWVER})"

if [ -z "${RELEASESTARTED}" ]; then
  git flow release start ${NEWVER}
  git push --set-upstream origin release/${NEWVER}
  git flow release finish ${NEWVER}
else
  git checkout new-master && git pull && git merge develop
fi
git push origin --tags
git push origin --all

git checkout develop

cd ../restructure-build
./build.sh

if [ ! -s ${CURRVERFILE} ]; then
  echo "${CURRVERFILE} in $(pwd) was not set. The build was not successful"
  exit 1
fi

TESTVER=$(cat ${CURRVERFILE})

if [ "${TESTVER}" == "${CURRVER}" ]; then
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
