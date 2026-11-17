#!/bin/bash

git remote show upstream > /dev/null || git remote add upstream https://github.com/consected/restructure.git
git fetch upstream
git checkout up-develop || ( git checkout -b up-develop upstream/develop && git branch --set-upstream-to=origin )
git pull
git checkout up-develop
git pull
git checkout develop
git merge up-develop -Xtheirs -m "Merge 'up-develop' onto develop" && git push
