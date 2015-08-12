FPHS_VERSION=`svn ls --username payres https://open.med.harvard.edu/svn/fphs-rails/tags | sort -V | tail -n 1`
FPHS_A=`echo $FPHS_VERSION | grep -oP '([0-9]+)' | tail -n 1`
FPHS_B=`echo $FPHS_VERSION | grep -oP '([0-9]+).([0-9]+).'`
FPHS_VERSION=$FPHS_B$((FPHS_A+1))
echo $FPHS_VERSION
DEV_DIR=~/NetBeansProjects/fpa1
cd $DEV_DIR
echo $FPHS_VERSION > version.txt
svn commit version.txt -m "new version file created"
svn rm --force public/assets
svn commit public/assets -m "clean up assets for deployment"
script/fphs/compile_assets.sh
pg_dump -d fpa_development -s > db/dumps/current_schema.sql
svn add public/assets
svn commit -m "Precompiled assets for release: $FPHS_VERSION"
svn copy https://open.med.harvard.edu/svn/fphs-rails/trunk/railsapp/ https://open.med.harvard.edu/svn/fphs-rails/tags/$FPHS_VERSION -m "Push to shared development"
