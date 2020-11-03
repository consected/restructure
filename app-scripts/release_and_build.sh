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

cd ../install-playbook/ansible
build_box=true vagrant up --provision
TESTVER=$(cat build_version.txt)

if [ "${TESTVER}" == "${CURRVER}" ]; then
  echo "Build failed"
  echo "${TESTVER} == ${CURRVER}"
  exit 1
fi

sed -i -E "s/git_version: .+/git_version: ${TESTVER}/g" package_vars.yml
setup_assets=true vagrant up --provision

cd ${CURRDIR}
echo ${TESTVER} > version.txt
git commit version.txt -m "Bump version"
git push
echo "Built and setup assets: ${TESTVER}"