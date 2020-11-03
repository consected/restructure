#####
#
# This script provides basic functionality run on Pandora to update to test version of the app without requiring Ansible to be run
#
#####
FPHS_VERSION=`svn ls --username payres https://open.med.harvard.edu/svn/fphs-rails/tags | sort -V | tail -n 1`
echo $FPHS_VERSION
cd /var/opt/passenger
svn export --username payres https://open.med.harvard.edu/svn/fphs-rails/tags/$FPHS_VERSION
cd $FPHS_VERSION
cp --recursive ../fphs/vendor/bundle ./vendor/
RAILS_ENV=production bundle install --without development test --path vendor/bundle --deployment
cd ..
mv fphs "fphs-backup-`date --rfc-3339=seconds`"
mv $FPHS_VERSION fphs
cd fphs
ln -s /var/opt/passenger/logs ./log
mkdir tmp
touch tmp/restart.txt