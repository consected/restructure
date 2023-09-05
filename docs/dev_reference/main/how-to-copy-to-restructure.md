# How to Copy to and from ReStructure

## From Private Repo To ReStructure

In ReStructure repo:

- Set the private repo name (harvard|viva|etc): `OTHER_REPO=harvard|viva|etc`
- Check out the appropriate rolling transfer branch `git checkout tx-${OTHER_REPO}-rolling; git pull`
- Set the current version variable: `RESTR_VERSION=$(cat ../../<private-repo-dir>/restructure/version.txt)`

In Private repo:

- Run `app-scripts/copy-to-restructure.sh ../../restructure/restructure`

In ReStructure repo:

- `git stage . ; git commit -a -m "Initial transfer"`
- Merge **develop** into the new branch to incorporate existing changes: `git merge --no-commit develop`
- Review the changes, which should just reflect those related to the last transfer - take care with:
  - config/initializers/app_settings.rb
  - config/database.yml
- Run:

```sh
bundle ; yarn
FPHS_LOAD_APP_TYPES=1 bundle exec rails db:migrate
FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data FPHS_LOAD_APP_TYPES=1 bundle exec rake db:structure:dump
app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh
# Login for sudo if required
app-scripts/parallel_test.sh
# Review the failures
less -r tmp/failing_specs.log
```

- Clean assets: `FPHS_LOAD_APP_TYPES=1 bundle exec rake assets:clobber`
- Commit the merge: `git commit -a -m "Merge branch develop into rolling branch"`
- Update the _CHANGELOG.md_ to include the appropriate changes
- Commit the changes: `git commit -a -m 'Updated CHANGELOG'`
- Push the branch
- Checkout **develop** branch: `git checkout develop ; git pull`
- Merge the transfer branch back into **develop**: `git merge tx-${OTHER_REPO}-rolling -m "Transferred from ${OTHER_REPO} @${RESTR_VERSION}"`

## From ReStructure to Private Repo

In Private repo:

- Check out the appropriate rolling transfer branch `git checkout tx-restructure-rolling ; git pull`
- Set the ReStructure current version variable: `RESTR_VERSION=$(cat ../../restructure/restructure/version.txt)`
- Run `app-scripts/copy-restructure-to-here.sh ../../restructure/restructure`
- `git stage . ; git commit -a -m "Initial transfer"`
- Merge **develop** into the new branch to incorporate existing changes: `git merge --no-commit develop`
- Run:

```sh
bundle ; yarn
FPHS_LOAD_APP_TYPES=1 bundle exec rails db:migrate
FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data FPHS_LOAD_APP_TYPES=1 bundle exec rake db:structure:dump
app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh
# Login for sudo if required
app-scripts/parallel_test.sh
# Review the failures
less -r tmp/failing_specs.log
```

- Clean assets: `FPHS_LOAD_APP_TYPES=1 bundle exec rake assets:clobber`
- Update the _CHANGELOG.md_ to include the appropriate changes
- Commit the changes: `git commit -a -m 'Updated CHANGELOG'`
- Push the branch
- Checkout **develop** branch: `git checkout develop ; git pull`
- Merge the transfer branch back into **develop**: `git merge tx-restructure-rolling -m "Transferred from ReStructure @${RESTR_VERSION}"`
