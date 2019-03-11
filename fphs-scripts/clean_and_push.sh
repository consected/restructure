bundle exec rake assets:clobber
rm -rf vendor/cache/*
git pull
bundle exec rake assets:clobber
rm -rf vendor/cache/*
git commit -a -m "Cleanup"
git push
