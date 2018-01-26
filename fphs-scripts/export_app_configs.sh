#!/bin/bash

pg_dump -a -f db/app_configs/bhs_config -d fphs -O -t ml_app.app_configurations
