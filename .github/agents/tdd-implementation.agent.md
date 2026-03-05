---
description: 'Implement code to satisfy GitHub issue requirements and make failing tests pass.'
name: 'TDD Implementation'
tools: ["vscode/*", "findTestFiles", "edit/editFiles", "edit/createFile", "edit/createDirectory", "execute/runInTerminal", "search/codebase", "filesystem", "search", "read/problems", "execute/testFailure", "read/terminalLastCommand", "execute/getTerminalOutput", "execute/awaitTerminal", "web/fetch", "read/problems", "read/readFile", "agent/runSubagent"]
agents: ['TDD Red Phase - Write Failing Tests First', 'TDD Green Phase - Make Tests Pass Quickly', 'TDD Refactor Phase - Improve Quality & Security']
---
# General Implementation

Follow TDD principles, recursively follow these steps using the following subagents:

- [TDD Red Phase - Write Failing Tests First](tdd-red.agent.md)
  - Focus on writing clear, specific failing tests that describe the desired behaviour from GitHub issue requirements before any implementation exists.
- [TDD Green Phase - Make Tests Pass Quickly](tdd-green.agent.md)
  - Write the minimal code necessary to satisfy GitHub issue requirements and make failing tests pass. Resist the urge to write more than required.

When all the requirements have been addressed and tested, move on to:

- [TDD Refactor Phase - Improve Quality & Security](tdd-refactor.agent.md)
  - Clean up code, apply security best practices, and enhance design whilst keeping all tests green and maintaining GitHub issue compliance.


## GitHub Issue Integration

### Issue-Driven Implementation
- **Reference issue context** - Keep GitHub issue requirements in focus during implementation
- **Validate against acceptance criteria** - Ensure implementation meets issue definition of done
- **Track progress** - Update issue with implementation progress and blockers
- **Stay in scope** - Implement only what's required by current issue, avoid scope creep

### Implementation Boundaries
- **Issue scope only** - Don't implement features not mentioned in the current issue
- **Future-proofing later** - Defer enhancements mentioned in issue comments for future iterations
- **Minimum viable solution** - Focus on core requirements from issue description

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
- Before starting work, add a tag `start-<feature-name>-<issue-number>` then create a features/bug branch `<feature-name>-<issue-number>`.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.

### Creating a Pull Request

If requested to create a PR, follow these steps:

- Rebase your branch onto the latest local `up-develop` branch before creating a pull request:
  `git checkout up-develop && git pull && git rebase --onto up-develop start-<feature-name>-<issue-number>`
- Create a (cross fork) pull request on repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes. "head" should refer to the local branch created for the feature.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.
