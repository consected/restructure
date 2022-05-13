# How to Copy to and from ReStructure

## From Private Repo To ReStructure

In ReStructure repo:

- Find the latest commit transferred from Private Repo to ReStructure `git log --all --max-count=1 --grep=tx-`
- Check it out `git checkout <commit-id>`
- Create a new branch `tx-<harvard|viva|etc>-@<current version>`

In Private repo:

- Run `app-scripts/copy-to-restructure.sh ../../restructure/restructure`

In ReStructure repo:

- Review the changes, which should just reflect those related to the last transfer - take care with:
  - config/initializers/app_settings.rb
  - config/database.yml
- Run:

```sh
bundle ; yarn
FPHS_LOAD_APP_TYPES=1 bundle exec rails db:migrate
FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data FPHS_LOAD_APP_TYPES=1 bundle exec rake db:structure:dump
app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh
app-scripts/parallel-test.sh
# Review the failures
less -r tmp/failing_specs.log
```

- Commit the changes that are required
- Checkout **develop** branch
- Merge the new transfer branch into **develop**
- Update the CHANGELOG to include the appropriate changes

## From ReStructure to Private Repo

In Private repo:

- Find the latest commit transferred from ReStructure to Private Repo `git log --all --max-count=1 --grep=tx-`
- Check it out `git checkout <commit-id>`
- Create a new branch `tx-restructure-@<current version>`
- Run `app-scripts/copy-restructure-to-here.sh`
- Review the changes, which should just reflect those related to the last transfer - take care with:
  - config/initializers/app_settings.rb
  - config/database.yml
- Run:

```sh
bundle ; yarn
FPHS_LOAD_APP_TYPES=1 bundle exec rails db:migrate
FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data FPHS_LOAD_APP_TYPES=1 bundle exec rake db:structure:dump
app-scripts/drop-test-db.sh ; app-scripts/create-test-db.sh
app-scripts/parallel-test.sh
# Review the failures
less -r tmp/failing_specs.log
```

- Commit the changes that are required
- Checkout **develop** branch
- Merge the new transfer branch into **develop**
- Update the CHANGELOG to include the appropriate changes
