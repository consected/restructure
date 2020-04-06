#!/bin/bash
CURRDIR=$(pwd)

if [ -z $(git branch | grep '* develop') ]; then
  echo "Must be on develop branch to get started"
  exit 1
fi

if [ ! -z "$(git status --porcelain=1)" ]; then
  echo "No files must be uncommitted"
  git status
  exit 1
fi

export NEWVER=$(VERSION_FILE=../install-playbook/ansible/build_version.txt fphs-scripts/upversion.rb -p)

git flow release start ${NEWVER}

cd ../install-playbook/ansible
build_box=true vagrant up --provision
sed -i -E "s/git_version: .+/git_version: ${NEWVER}/g" package_vars.yml
setup_assets=true vagrant up --provision

cd ${CURRDIR}
