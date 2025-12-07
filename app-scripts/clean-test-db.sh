#!/bin/bash
# Quickly clean and reset the test database (just a single database, not all for parallel tests)


export USE_PG_UNAME=${USE_PG_UNAME:=$(whoami)}
echo "Cleaning a single test database with user Postgres user: ${USE_PG_UNAME}"
app-scripts/drop-test-db.sh 1
app-scripts/create-test-db.sh 1
reset