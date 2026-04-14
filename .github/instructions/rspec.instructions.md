---
applyTo: 'spec/**'
---

# Rspec System Specs project coding standards

## Quick Reference
- Check for reusable support methods in `spec/support/` before writing new test code.
- After writing tests, always add comments to the top of the spec files explaining the purpose of the tests.
- Create new system specs in `spec/system/` - refer to [Rspec System Specs project coding standards](rspec-system-spec.instructions.md)
- Use schema name `dynamic_test` for test dynamic models, activity logs and external identifiers
- Be sure to read the Rails logger output in `log/test.log` for errors not shown in Rspec output

## Running Bash Scripts and Terminal Commands

### IMPORTANT Terminal Command Rules for AI Agents

#### ❌ NEVER Do These Things

```bash
# ❌ Setting environment variables (scripts handle this internally)
RAILS_ENV=test bundle exec rspec
FPHS_2FA_AUTH_DISABLED=true bundle exec rails runner "puts 'test'"

# ❌ Piping long-running commands (lose visibility into progress and errors)
bundle exec rspec spec/system/ 2>&1 | grep "Error" | tail -15

# ❌ Running in background (can't track completion or errors)
nohup bundle exec rspec spec/system/ &
bundle exec rspec spec/system/ > /tmp/output.log 2>&1 &

# ❌ Redirecting output to /dev/null (lose debugging information)
bundle exec rspec spec/system/ >/dev/null 2>&1
bundle exec rspec spec/system/ 2>/dev/null

# ❌ Clearing the assets and cache manually
rm -rf tmp/cache/assets && rm -rf public/assets
```

#### ✅ ALWAYS Do This Instead

```bash
# ✅ Let test output stream, then analyze the saved log
bundle exec rspec spec/system/ 2>&1 | tee /tmp/rspec_output.log | tail -100
grep -E "pattern" /tmp/rspec_output.log | tail -15
grep -E --after-context=100 "other pattern" /tmp/rspec_output.log | tail -200

# ✅ Use app-scripts that set environment variables internally
# NOTE: the arguments after the script are the same as you would pass to the underlying command
# Replace `RAILS_ENV=test bundle exec rails runner ...` with: 
app-scripts/rails_runner_test.sh "puts User.count"
# or use the rails environment argument
bundle exec rails runner -e test "puts Rails.env"

# Replace `RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec ...` with:
app-scripts/headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'

# Replace `NOT_HEADLESS=true RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec ...` with:
app-scripts/not_headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'

# Clean the test database (creates a fresh one)
app-scripts/clean-test-db.sh 

# Clean test assets and cache
app-scripts/clean-test-assets-and-cache.sh
```

#### Why These Rules Exist

- **Terminal tools can lose output** if commands pipe before completion
- **Background processes hide errors** and completion status from the agent
- **Environment variables must be consistent** - app-scripts ensure this
- **Tee allows both viewing and analyzing** output without losing information
- **Agents need full output** to diagnose failures accurately

## Testing Approach

Background to the test framework and conventions:

- **RSpec**: Main test framework with parallel execution support
- **Capybara**: systems tests with Chrome by default, or Firefox/Geckodriver
- **Database Cleaner**: Test isolation
- **Model specs** must be produced to cover all new model logic
- **System specs** (not features specs) should be produced for all new UI functionality
- **Run `rspec` on new spec tests** after implementing new features to make sure they run
- **Do not use `skip` or `xit` in spec files**. Instead, fix the underlying issues causing test failures. 

## Running tests
Before running tests for the very first time after a reboot, set up the filestore simulation. Tests require Filestore mount setup once only after a system restart: 
```bash
app-scripts/setup-dev-filestore.sh
```
NOTE: this needs "sudo" to run, and although the Rspec suite attempts to run this automatically if required, it is best to run this manually once after a reboot to avoid test failures.

Standard Rspec tests, which exclude environment / app specific tests in 
`spec/system/apps/` and `spec/support/apps/`
```bash
bundle exec rspec  # Run in headless mode
```

For headless (invisible browser) system tests, which include the environment / app specific specs:
```bash
app-scripts/headless_rspec.sh spec/system/apps/grant_aims/grant_aims_process_spec.rb
```

For non-headless (visible browser) system tests, which include the environment / app specific specs:
```bash
app-scripts/not_headless_rspec.sh spec/system/apps/grant_aims/grant_aims_process_spec.rb
```

For javascript tests (in `spec/javascripts/`):
```bash
app-scripts/jasmine-serve.sh headless
```

AI Agents: to use the Rails runner, use one of the following:

```bash
app-scripts/rails_runner_test.sh "<command to run>"
# Or
bundle exec rails runner -e test "<command to run>"
```

AI Agents: DO NOT use environment variables
```bash
RAILS_ENV=test bundle exec rails runner "<command to run>"
```

If needed, clean the test database:
```bash
app-scripts/clean-test-db.sh

```
If needed, clean test assets and cache:
```bash
app-scripts/clean-test-assets-and-cache.sh
```
## Parallel test execution
```bash
app-scripts/parallel_test.sh
```
NOTE: the full test suite is slow, so only run when a full coverage test is required! Add arguments for spec paths if required.

The results are found in tmp/failing_specs.log or on the console. Any issues are reported by the final section after the "Retesting" of any failures has completed.

To rerun only the failed tests from the last parallel test run:
```bash
app-scripts/retest_failed_parallel_tests.sh
```

