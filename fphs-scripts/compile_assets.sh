#!/bin/sh
FPHS_RAILS_DEVISE_SECRET_KEY='rake' FPHS_RAILS_SECRET_KEY_BASE='rake' RAILS_ENV=production rake assets:clobber
FPHS_RAILS_DEVISE_SECRET_KEY='rake' FPHS_RAILS_SECRET_KEY_BASE='rake' RAILS_ENV=production rake assets:precompile --trace