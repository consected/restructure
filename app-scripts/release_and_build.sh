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

ALLTAGS="$(git tag --sort=-taggerdate)"
CURRVER=$(cat ../install-playbook/ansible/build_version.txt)
NEWVER="$(VERSION_FILE=../install-playbook/ansible/build_version.txt app-scripts/upversion.rb -p)"
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

if [ ! -s shared/build_version.txt ]; then
  echo "shared/build_version.txt in $(pwd) was not set. The build was not successful"
  exit 1
fi

TESTVER=$(cat shared/build_version.txt)

if [ "${TESTVER}" == "${CURRVER}" ]; then
  echo "Build failed"
  echo "${TESTVER} == ${CURRVER}"
  exit 1
else
  echo "Build successful"
fi

git fetch origin
git checkout new-master
git checkout develop
git merge new-master
echo "Built and setup assets: ${TESTVER}"
