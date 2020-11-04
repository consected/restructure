####
#
# This script provides a quick update and test of using brakeman and bundle-audit gems
#
####
if [ -n "$FPHS_VERSION" ]
then
brakeman -o ./security/brakeman-output-$FPHS_VERSION.md
bundle-audit update > ./security/bundle-audit-update-$FPHS_VERSION.md
bundle-audit check > ./security/bundle-audit-output-$FPHS_VERSION.md
else
brakeman
bundle-audit update
bundle-audit check
fi