#!/bin/sh
FPHS_POSTGRESQL_DATABASE='fpa_development' FPHS_RAILS_DEVISE_SECRET_KEY='rake' FPHS_RAILS_SECRET_KEY_BASE='rake' RAILS_ENV=production rake assets:clobber
FPHS_POSTGRESQL_DATABASE='fpa_development' FPHS_RAILS_DEVISE_SECRET_KEY='rake' FPHS_RAILS_SECRET_KEY_BASE='rake' RAILS_ENV=production rake assets:precompile --trace