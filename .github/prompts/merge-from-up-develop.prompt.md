name: merge-from-up-develop
description: Merge the latest changes from up-develop into the local develop branch
model: Claude Opus 4.6 (copilot)
---
### Merge Latest Changes from up-develop

If requested to merge the latest changes from `up-develop` into the local `develop` branch, follow these steps:

```
git checkout develop
git pull
git checkout up-develop
git pull
git checkout develop
git merge up-develop -Xtheirs -m "Merge 'up-develop' onto develop" && git push
```

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
