# "Forking" to a Private Repository

Github doesn't allow a public repository to be forked and then the fork to be made private. This process allows a private repo to be generated from the _upstream_ private repo.

## Create a private repository

To generate a new repository for private development

- Create a new repository in the organization of your choice
- Ensure the new repo is private
- Get the code and set up the upstream URL

```sh
PRIVATE_ORG=<your private github organization>
mkdir ${PRIVATE_ORG}
cd ${PRIVATE_ORG}
git clone https://github.com/consected/restructure
cd restructure
git remote set-url origin https://github.com/${PRIVATE_ORG}/restructure
git remote add upstream https://github.com/consected/restructure
git fetch upstream
```

## Incorporate changes made upstream

To incorporate changes from upstream into the private repository

    git fetch upstream
    git diff upstream/develop develop

The diff will allow us to check if we need to rebase

Now create a branch for the changes

    git checkout -b <branch name>
    git pull upstream develop
    git push origin <branch name>

## Sending changes back upstream

Make sure you have pulled in the latest changes from the public repo into the private repo and merge any pending pull requests into the _develop_ branch of the private repo. At a minimum...

```sh
cd consected/restructure
git checkout develop
git pull

```

On the public repo, add the private repo as a new upstream remote

```sh
cd consected/restructure
git remote add downstream https://github.com/${PRIVATE_ORG}/restructure
```

Create a new branch on the public repo

    git checkout -b <branch name>

To retain the full history, rebase the _develop_ branch of the private repo onto the new branch

    git fetch downstream
    git rebase downstream/develop
    git rebase develop

Or to apply the latest changes onto the top of _develop_ as uncommitted changes (allowing for selective commits)

    git fetch downstream
    git merge downstream/develop --no-commit

Raise a PR on the public repo for the new branch

Once the PR is complete, if there are no more changes expected from downstream

    git remote remove downstream

---

_NOTE:_ adapted from <https://docs.publishing.service.gov.uk/manual/make-github-repo-private.html>
