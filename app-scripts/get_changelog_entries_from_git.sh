#!/bin/bash
# Run with --update-cl to also update CHANGELOG.md

if [ ! -f CHANGELOG.md ]; then
  echo 'Must run this script from the root of the repository'
  exit 1
fi

while [ "$1" ]; do
  case "$1" in
    --update-cl)
      update_cl=true
      echo 'Also updating CHANGELOG.md'
      shift
      ;;
    --prs)
      prs=true
      echo 'Use merged PRs in CHANGELOG.md'
      shift
      ;;
    *)
      base_branch="$1"
      shift
      ;;
  esac
done

base_branch=${base_branch:=new-master}
feature_branch="$(git branch --show-current)"
if [ ${base_branch} != ${feature_branch} ]; then
  git checkout ${base_branch} > /dev/null 2>&1 && git pull origin ${base_branch} > /dev/null 2>&1 && \
  git checkout ${feature_branch} > /dev/null 2>&1
  [ "${feature_branch}" == "$(git branch --show-current)" ]
else
  git pull origin ${base_branch} > /dev/null 2>&1
fi

if [ $? -ne 0 ]; then
  echo "Failed to checkout feature branch: ${feature_branch}"
  exit 1
fi

if [ "$prs" == "true" ]; then
  resfile=$(mktemp)
  git log --format=%b%n --merges new-master..HEAD > tmpchangelogfile

  if [ "$update_cl" == "true" ]; then
    sed -i -E "s/## Unreleased/## Unreleased\n****/" CHANGELOG.md
    sed -i -e '/[*][*][*][*]/{r tmpchangelogfile' -e 'd}' CHANGELOG.md
    rm tmpchangelogfile
  fi
else
  oldifs=$IFS
  IFS=$'\n'
  for line in $(git log --format=%s --no-merges ${base_branch}..HEAD) ; do 
    [[ $line =~ ^([a-zA-Z]+)\ (.+) ]]
    if [ -z "${BASH_REMATCH[1]}" ] || [ -z "${BASH_REMATCH[2]}" ]; then
      echo "Bad git log entry: ${line}"
      continue
    fi
    res="$(echo "- [${BASH_REMATCH[1]}] ${BASH_REMATCH[2]}")"
    echo "$res"
    if [ "$update_cl" == "true" ]; then
      sed -i -E "s/## Unreleased/## Unreleased\n${res}/" CHANGELOG.md
    fi
  done
  IFS=$oldifs
fi

if [ "$update_cl" == "true" ]; then
  sed -i -E "s/## Unreleased/## Unreleased\n/" CHANGELOG.md
fi