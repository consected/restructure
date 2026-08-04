name: createpr-nosquash
description: Create a new pull request using our workspace workflow without squashing commits
---
### Creating a Pull Request

If requested to create a PR without squashing commits, follow these steps:

- Ensure files have been formatted and linted according to our workspace standards
- Ensure all work has been commited to the feature branch
- Only squash commits so that there is a single commit per logical change, with a clear message describing the change and referencing the related issue number (e.g. "Added feature X - fixes #123")
- Rebase your branch onto the latest local `up-develop` branch before creating a pull request
- Create a (cross fork) pull request on repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes. "head" should refer to the local branch created for the feature.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.

Create a PR body file in `tmp/agent-tmp/pr-body-<issue-number>.md` directly, rather than using command line tools (since these lead to quoting, backticks and other escaping issues).

Step-by-step commands to create the PR after squashing commits for logical changes:
```sh
git checkout up-develop && git pull
git checkout <branch-name> && git rebase --onto up-develop start-<branch-name>
git push -u origin <branch-name> --force-with-lease
cd /home/phil/NetBeansProjects/fphs/fphs-restructure && \
gh pr create --repo consected/restructure --base develop --head hmsrc:<branch-name> --title "<commit message>" --body-file tmp/agent-tmp/pr-body-<issue-number>.md
```


### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
- Before starting work, add a tag `start-<feature-name>-<issue-number>` then create a features/bug branch `<feature-name>-<issue-number>`.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.
