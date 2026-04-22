name: rebase-on-up-develop
description: Rebase a feature branch onto the latest up-develop branch
model: Claude Opus 4.6 (copilot)
---
### Rebase Feature Branch Onto Latest up-develop

If requested to rebase a feature branch onto the latest `up-develop` branch, follow these steps:

- Pull the latest changes from the `up-develop` branch to ensure you have the most recent updates.
- Check out the feature branch that needs to be rebased.
- Rebase the feature branch onto `up-develop` using the `git rebase --onto` command, specifying the starting point of the feature branch (the "start-<branch-name>" tag).
- Push the rebased branch to the remote repository, using `--force-with-lease` to safely update the branch without overwriting any changes that may have been pushed by others.
- Update the `start-<branch-name>` tag to point to the new base of the feature branch after rebasing.

```
git checkout up-develop && git pull
git checkout <branch-name> && git rebase --onto up-develop start-<branch-name>
git push -u origin <branch-name> --force-with-lease
git tag -f start-<branch-name> up-develop
```

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
