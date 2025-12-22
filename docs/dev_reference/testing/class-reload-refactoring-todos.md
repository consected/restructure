# Class Reload Refactoring TODOs

## Background

The `before :each` check in `rails_helper.rb` (lines 296-304) validates that instance variables haven't been assigned objects whose classes have been reloaded. This prevents hard-to-debug failures caused by stale class references.

## Problem Pattern

When Rails reloads classes during parallel test execution:

- Instance variables assigned in one example may hold objects whose classes get reloaded
- Subsequent examples that access these variables will fail `is_a?` checks
- This manifests as `AssociationTypeMismatch`, `NoMethodError`, or other cryptic failures

## Solution

Instead of working around class reloading (e.g., checking `user.class.name == 'User'`), **refactor tests** to:

1. Move object creation into `before :each` or `let` blocks
2. Avoid reusing instance variables across examples
3. Re-create objects in each example that needs them

## Files Requiring Refactoring

### Actual Failures Found in Parallel Test Run

1. **spec/models/dynamic/def_config_triggers_spec.rb** - FIXED
   - Lines 25, 33, 38: `@als` (ActiveRecord::Relation) assigned in `generate_test_al` method called from `before :all`
   - **Solution Applied**: Changed `@als` to local variable `als` since it's only used within the method
   - Test failures: "creates an activity log with default user access control and embedded item", "will not break existing configurations when an activity log with config_trigger is rerun", "add configurations using the app import format"

2. **spec/models/nfs_store/manage/container_file_spec.rb** - NEEDS INVESTIGATION
   - Test: "uploads a file and creates a StoredFile"
   - Error: "Attempting to set current_user with non user" - User class reloaded between setup and execution
   - Cause: User object created in `setup_nfs_store` (called from `before :each`) but class reloads before assignment
   - **Action Needed**: Investigate why User class reloads between creation and usage in same example

3. **spec/models/nfs_store/process/process_handler_spec.rb** - NEEDS INVESTIGATION
   - Test: "defines a custom pipeline"
   - Error: Same "Attempting to set current_user with non user" error
   - **Action Needed**: Similar User class reload issue

4. **spec/models/delete_stored_files_spec.rb** - NEEDS INVESTIGATION
   - Test: "delete a stored file from a container"
   - Error: Same "Attempting to set current_user with non user" error
   - **Action Needed**: Similar User class reload issue

### Previously Identified (Need Verification - Some Were False Positives)

These files have instance variable assignments in example bodies that could cause issues:

1. **spec/models/model_reference_spec.rb** (lines 28-33, 76)
   - `@player_contact1`, `@player_contact2`, `@player_contact3` assigned in examples
   - `@activity_log`, `@working_data`, `@address` assigned in examples
   - **Action**: Move to `before :each` or recreate in each example

2. **spec/models/master_spec.rb** (lines 246-249)
   - `@contact_1`, `@contact_2`, `@contact_3` assigned in examples
   - **Action**: Move to `before :each` block or use `let!`

3. **spec/models/conditional_actions_spec.rb** (multiple locations)
   - Lines 153-154, 258-260, 408-409: User objects created in examples
   - Lines 10, 93, 158, 264, 413: Config hashes assigned
   - Lines 156, 262, 411: Test objects created
   - **Action**: Move user/object creation to `before :each` blocks

4. **spec/models/nfs_store/archive/mounter_spec.rb** (lines 21-33, 154-166)
   - Multiple file and container objects assigned in examples
   - **Action**: Consolidate into proper setup blocks

### Pattern to Search For

```bash
# Find all instance variable assignments outside before/let/subject blocks
grep -rn "@[a-z0-9_]* = " spec/ --include="*_spec.rb" | \
  grep -v "before\|let\|subject" | \
  grep -v "spec_helper.rb"
```

### Server Restart Monitoring

When system specs output `*** Server restart requested ***`, it indicates class reloading. Any instance variables set before this point and used after will be stale.

**Action Items:**

1. Monitor parallel test output for restart messages
2. Identify specs that set instance variables before restarts
3. Refactor those specs to recreate objects after reloads

## Testing Strategy

1. **Run specs individually first**: `bundle exec rspec path/to/spec.rb`
   - Ensures spec logic is correct

2. **Run with parallel tests**: `app-scripts/parallel_test.sh`
   - Exposes class reload issues

3. **Check rails_helper.rb guard**: The `before :each` check will fail with clear message if objects are stale

## Example Refactoring

### Before (Problematic)

```ruby
RSpec.describe MyModel do
  before :all do
    @user = create_user  # Created once, class may reload
  end

  it 'does something' do
    @user.some_method  # May fail if User class reloaded
  end

  it 'does another thing' do
    @user.another_method  # Same stale object
  end
end
```

### After (Fixed)

```ruby
RSpec.describe MyModel do
  # Option 1: Use before :each
  before :each do
    @user = create_user  # Fresh object for each example
  end

  # Option 2: Use let
  let(:user) { create_user }  # Lazy-loaded, fresh each time

  it 'does something' do
    user.some_method
  end

  it 'does another thing' do
    user.another_method
  end
end
```

## Reverted Changes

The following workarounds have been reverted to enforce proper test design:

1. **app/models/master.rb** (line 342)
   - Removed: `|| user.class.name == 'User'` check
   - Tests must ensure User objects are fresh

2. **app/models/nfs_store/upload.rb** (lines 20-33)
   - Removed: Custom `stored_file=` override
   - Tests must ensure StoredFile objects are fresh

## Next Steps

1. **Prioritize refactoring** the files listed above
2. **Run parallel tests** to identify additional failures
3. **Document patterns** as more cases are discovered
4. **Update this file** with completed refactorings
