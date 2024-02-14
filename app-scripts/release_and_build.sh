#!/bin/bash

echo "Starting release and build"
CURRDIR="$(pwd)"

if [ "$1" == 'clean' ]; then
  build_arg='clean'
  echo 'Cleaning up old container and rebuilding it from scratch'
fi

if [ "$1" == 'minor' ] || [ "$2" == 'minor' ]; then
  echo 'Minor version'
  UPVLEVEL=minor
fi

export GIT_MERGE_AUTOEDIT=no

FROM_BRANCH=${FROM_BRANCH:=develop}

ONDEVELOP="$(git branch | grep '* '${FROM_BRANCH})"
if [ -z "${ONDEVELOP}" ]; then
  echo "Must be on ${FROM_BRANCH} branch to get started"
  exit 1
fi

GITSTATUS="$(git status --porcelain=1)"
if [ ! -z "${GITSTATUS}" ]; then
  echo "No files must be uncommitted"
  git status
  exit 1
fi

git pull
if [ $? != 0 ]; then
  echo "Failed initial git pull on $(git branch --show-current)"
  exit 2
fi

cl_ur=$(grep '## Unreleased' CHANGELOG.md)
if [ -z "${cl_ur}" ]; then
  echo "CHANGELOG.md does not have the section '## Unreleased'. Edit and retry."
  exit 2
fi

cl_not_ok=$(grep -Pzl '## Unreleased\n+## ' CHANGELOG.md)
if [ "${cl_not_ok}" ]; then
  echo "CHANGELOG.md does not have anything entered for the Unreleased section. Edit and retry."
  exit 2
fi

head -32 CHANGELOG.md | tail -13

echo "Clean up assets before we start"
FPHS_LOAD_APP_TYPES=1 bundle exec rake assets:clobber
git commit public/assets -m "Cleanup"
git push

GENVERFILE=shared/build_version.txt
CURRVERFILE=version.txt
ALLTAGS="$(git tag --sort=-taggerdate)"
LASTTAG=$(echo "${ALLTAGS/-dev/}" | head -n1)
CURRVERINFILE=$(cat ${CURRVERFILE})
CURRVER=${CURRVERINFILE}

if [ "${CURRVERINFILE}" != "${LASTTAG}" ]; then
  echo "Latest version file version ${CURRVER} and latest tag ${LASTTAG} do not match"
  read -p 'Use latest file version (1), latest tag version (2) or manual entry for latest version (3)? ' USEVER

  if [ "$USEVER" == '1' ]; then
    LASTTAG=${CURRVER}
  elif [ "$USEVER" == '2' ]; then
    CURRVER=${LASTTAG}
    echo ${CURRVER} > ${CURRVERFILE}
    git commit version.txt -m '[Bumped] patch version to latest tag'
    git push
  elif [ "$USEVER" == '3' ]; then
    read -p 'Enter version to use (this will be upversioned to the next version): ' SETVER
    CURRVER=${SETVER}
    echo ${CURRVER} > ${CURRVERFILE}
    git commit version.txt -m '[Bumped] patch version manually'
    git push
  else
    echo 'Bad selection'
    exit 9
  fi
fi

if [ "${UPVLEVEL}" == 'minor' ]; then
  CURRVER="$(VERSION_FILE=${CURRVERFILE} app-scripts/upversion.rb -p minor)"
  echo ${CURRVER} > ${CURRVERFILE}
  git commit version.txt -m '[Bumped] minor version'
  git push
fi

NEWVER="$(VERSION_FILE=${CURRVERFILE} app-scripts/upversion.rb -p)"
RELEASESTARTED="$(echo "${ALLTAGS}" | grep ${NEWVER})"

echo "Current version: ${CURRVER}"
echo "Next version: ${NEWVER}"

source ../restructure-build/shared/build-vars.sh
if [ "$(cat .ruby-version)" != ${RUBY_V} ]; then
  echo "Ruby versions don't match: $(cat .ruby-version) != ${RUBY_V}"
  exit 7
fi

if [ "${RELEASESTARTED}" ]; then
  echo "Tag ${NEWVER} already exists. Try:"
  echo "app-scripts/upversion.rb; git commit version.txt -m 'Bumped version'; git push"
  exit 55
fi

if [ -z "${SKIP_BRAKEMAN}" ]; then
  echo "Checking brakeman and bundle-audit before we go through the whole process"
  bin/brakeman -q --summary > /tmp/fphs-brakeman-summary.txt
  if [ "$?" == 0 ]; then
    echo "Brakeman OK"
  else
    cat /tmp/fphs-brakeman-summary.txt
    echo "Brakeman Failed"
    exit 1
  fi

  bundle exec bundle-audit update 2>&1
  bundle exec bundle-audit check 2>&1 > /tmp/bundle-audit-output.md
  RES=$?
  if [ "${RES}" == 0 ]; then
    echo "bundle-audit OK"
  else
    echo "bundle-audit Failed: ${RES}"
    cat /tmp/bundle-audit-output.md
    exit 1
  fi
fi

# RELNUM=$(git flow release)
# if [ "${RELNUM}" ]; then
#   echo "Release already started. Checking out and continuing"
#   git flow release delete -f ${RELNUM}
# fi

echo "Starting release to new-master"
git checkout new-master && git pull
if [ $? != 0 ]; then
  echo "Failed to checkout new-master. Will not continue."
  exit 105
fi
# git checkout ${FROM_BRANCH}
# git flow release start ${NEWVER}
# RES=$?
# if [ "$RES" != "0" ]; then
#   echo $RES
#   exit
# fi
# git push --set-upstream origin release/${NEWVER}
# git flow release finish -m 'Release' ${NEWVER}
# git push origin --tags
git merge --no-ff ${FROM_BRANCH}
if [ $? != 0 ]; then
  echo "Failed to merge ${FROM_BRANCH}. Will not continue."
  exit 102
fi

git push origin --all
if [ $? != 0 ]; then
  echo "Failed to push orign. Will not continue."
  exit 103
fi

git checkout ${FROM_BRANCH}
if [ $? != 0 ]; then
  echo "Failed to checkout ${FROM_BRANCH}. Will not continue."
  exit 104
fi

echo "Starting build container"
cd ../restructure-build
./build.sh ${build_arg}
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
git checkout ${FROM_BRANCH}
git pull
git merge new-master
git push
echo "Built and setup assets: ${TESTVER}"
