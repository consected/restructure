name: createpr
description: Create a new pull request using our workspace workflow
model: Claude Opus 4.6 (copilot)
---
### Creating a Pull Request

If requested to create a PR, follow these steps:

- Ensure files have been formatted and linted according to our workspace standards
- Ensure all work has been commited to the feature branch
- Squash commits into a single commit with a clear message describing the change and referencing the related issue number (e.g. "Added feature X - fixes #123"): use `git reset --soft...`
- Rebase your branch onto the latest local `up-develop` branch before creating a pull request
- Create a (cross fork) pull request on repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes. "head" should refer to the local branch created for the feature.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.

Step-by-step commands to create the PR:
```sh
git reset --soft start-<branch-name> && git commit -m "<commit message>"
git checkout up-develop && git pull
git checkout <branch-name> && git rebase --onto up-develop start-<branch-name>
git push -u origin <branch-name> --force-with-lease
cd /home/phil/NetBeansProjects/fphs/fphs-restructure && \
gh pr create --repo consected/restructure --base develop --head hmsrc:<branch-name> --title "<commit message>" --body-file tmp/agent-tmp/pr-body-<issue-number>.md
```

IMPORTANT: escape backticks when used in the command line.

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
- Before starting work, add a tag `start-<feature-name>-<issue-number>` then create a features/bug branch `<feature-name>-<issue-number>`.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.
