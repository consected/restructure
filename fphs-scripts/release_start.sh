#!/bin/bash
CURRDIR="$(pwd)"

ONDEVELOP=$(git branch | grep '* develop')
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

TOPTAG="$(git tag --sort=-taggerdate | head -1)"
export NEWVER=$(VERSION_FILE=../install-playbook/ansible/build_version.txt fphs-scripts/upversion.rb -p)

RELEASESTARTED=$(echo ${TOPTAG} | grep ${NEWVER})

if [ -z "${RELEASESTARTED}" ]; then
  git flow release start ${NEWVER}
  git push
else
  git checkout new-master && git pull && git merge develop || echo "Failed!" && exit
  git push
fi

cd ../install-playbook/ansible
build_box=true vagrant up --provision
sed -i -E "s/git_version: .+/git_version: ${NEWVER}/g" package_vars.yml
setup_assets=true vagrant up --provision

cd ${CURRDIR}
