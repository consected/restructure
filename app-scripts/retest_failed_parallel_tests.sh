#!/bin/bash
# Simply run the failed tests from the last parallel_test.sh run

RUN_RESTESTS=true QUIETLY=true app-scripts/parallel_test.sh