name: createpr
description: Create a new pull request using our workspace workflow
---
### Creating a Pull Request

If requested to create a PR, follow these steps:

- Squash commits into a single commit with a clear message describing the change and referencing the related issue number (e.g. "Added feature X - fixes #123").
- Rebase your branch onto the latest local `up-develop` branch before creating a pull request:
  `git checkout up-develop && git pull && git rebase --onto up-develop start-<feature-name>-<issue-number>`
- Create a (cross fork) pull request on repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes. "head" should refer to the local branch created for the feature.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
- Before starting work, add a tag `start-<feature-name>-<issue-number>` then create a features/bug branch `<feature-name>-<issue-number>`.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.
