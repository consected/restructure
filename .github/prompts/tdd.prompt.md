name: tdd
description: Run TDD Red, Green, and Refactor Phases
agent: tdd-implementation
tools: [execute, read, edit, search, web, agent, todo]
---

Run **TDD Implementation** agent

Read the copilot instructions. Get the specified Github issue. Create a feature branch. Then follow TDD principles, recursively follow these steps using the following subagents:

- [TDD Red Phase - Write Failing Tests First](tdd-red.agent.md)
  - Focus on writing clear, specific failing tests that describe the desired behaviour from GitHub issue requirements before any implementation exists.
- [TDD Green Phase - Make Tests Pass Quickly](tdd-green.agent.md)
  - Write the minimal code necessary to satisfy GitHub issue requirements and make failing tests pass. Resist the urge to write more than required.

When all the requirements have been addressed and tested, move on to:

- [TDD Refactor Phase - Improve Quality & Security](tdd-refactor.agent.md)
  - Clean up code, apply security best practices, and enhance design whilst keeping all tests green and maintaining GitHub issue compliance.

