####
#
# This script provides a quick update and test of using brakeman and bundle-audit gems
#
####
brakeman -o ./security/brakeman-output-$FPHS_VERSION.md
bundle-audit update > ./security/bundle-audit-update-$FPHS_VERSION.md
bundle-audit check > ./security/bundle-audit-output-$FPHS_VERSION.md
