export FPHS_VERSION=`svn ls --username payres https://open.med.harvard.edu/svn/fphs-rails/tags | sort -V | tail -n 1`
FPHS_A=`echo $FPHS_VERSION | grep -oP '([0-9]+)' | tail -n 1`
FPHS_B=2.0.
#`echo $FPHS_VERSION | grep -oP '([0-9]+).([0-9]+).'`
export FPHS_VERSION=$FPHS_B$((FPHS_A+1))
echo $FPHS_VERSION
export DEV_DIR=`pwd`
cd $DEV_DIR
echo $FPHS_VERSION > version.txt
svn commit version.txt -m "new version file created `cat version.txt`"
svn rm --force public/assets
svn commit public/assets -m "clean up assets for deployment"
fphs-scripts/compile_assets.sh
fphs-scripts/run_sec_tests.sh 
svn add security/*$FPHS_VERSION*
svn commit security -m "store security test results"
pg_dump -O -T ml_copy -d fpa_development -s > db/dumps/current_schema.sql
svn add public/assets
svn commit -m "Precompiled assets for release: $FPHS_VERSION"
svn copy https://open.med.harvard.edu/svn/fphs-rails/branches/phase2/admin_reports/railsapp/ https://open.med.harvard.edu/svn/fphs-rails/tags/$FPHS_VERSION -m "Push release"
