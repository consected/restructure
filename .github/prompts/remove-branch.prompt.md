name: remove-branch
description: Remove a feature branch after merging a pull request
model: Claude Opus 4.6 (copilot)
---
### Remove Feature Branch After Merging a Pull Request

If requested to remove a feature branch, follow these steps:

- Check the branch has been merged into `up-develop` and is no longer needed.
- Delete the local and remote feature branch.
- Delete the corresponding start tag, if it exists.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
