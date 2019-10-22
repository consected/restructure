#
# Source this file to setup the appropriate connection variables to support Elaine App synchronizations
# This file may be reused across multiple sync scripts (BHS, IPA, etc), therefore take care if moving or editing it
#

if [ -z "$RAILS_ENV" ]
then
  echo RAILS_ENV is not set. Exiting
  exit 1
fi
export RAILS_ENV

echo Sync environment: $RAILS_ENV

# if [ "$RAILS_ENV" == 'development' ]
# then
#   # Connection details for the demo FPHS Zeus database
#   export ZEUS_DB=fphs_demo
#   export ZEUS_FPHS_DB_SCHEMA=ml_app,ipa_ops,persnet
#   export ZEUS_FPHS_DB_HOST=localhost
#   export ZEUS_FPHS_DB_USER=fphsetl
#   # Connection details for the demo AWS Elaine database
#   export AWS_DB=fpa_development
#   export AWS_DB_SCHEMA=ml_app,ipa_ops,persnet
#   export AWS_DB_HOST=localhost
#   export AWS_DB_USER=fphsetl
#
#   export upload_server="http://localhost:3001"
#   export upload_user_email="sync_service_file_upload_client@app.fphs2.harvard.edu"
#   export upload_user_token="c2PdFBzTs_DjqA3md-8n6Nxc5wtLFQ"
#
# fi

if [ "$RAILS_ENV" == 'development' ]
then
  # Connection details for the demo FPHS Zeus database
  export ZEUS_DB=fpa_development
  export ZEUS_FPHS_DB_SCHEMA=ml_app,ipa_ops,persnet,sleep
  export ZEUS_FPHS_DB_HOST=localhost
  export ZEUS_FPHS_DB_USER=phil
  # Connection details for the demo AWS Elaine database
  export AWS_DB=ebdb
  export AWS_DB_SCHEMA=ml_app,ipa_ops,persnet,sleep
  export AWS_DB_HOST=fphs-aws-db-dev01.c9dljdsduksr.us-east-1.rds.amazonaws.com
  export AWS_DB_USER=fphsetl

  export upload_server="http://localhost:3001"
  export upload_user_email="sync_service_file_upload_client@app.fphs2.harvard.edu"
  export upload_user_token="c2PdFBzTs_DjqA3md-8n6Nxc5wtLFQ"

fi


if [ "$RAILS_ENV" == 'test' ]
then
  # Connection details for the demo FPHS Zeus database
  export ZEUS_DB=fphs_demo
  export ZEUS_FPHS_DB_SCHEMA=ml_app,ipa_ops,persnet
  export ZEUS_FPHS_DB_HOST=localhost
  export ZEUS_FPHS_DB_USER=fphsetl
  # Connection details for the remote AWS Elaine database
  export AWS_DB=fpa_test
  export AWS_DB_SCHEMA=ml_app
  export AWS_DB_HOST=localhost
  export AWS_DB_USER=fphsetl
fi

if [ "$RAILS_ENV" == 'production' ]
then

  if [ "$EBENV" == 'DEV-fphs' ]
  then
    # Connection details for the local FPHS Zeus database for DEV-fphs
    export ZEUS_DB=ebdb
    export ZEUS_FPHS_DB_SCHEMA=ml_app_zeus_full
    export ZEUS_FPHS_DB_HOST=fphs-aws-db-dev01.c9dljdsduksr.us-east-1.rds.amazonaws.com
    export ZEUS_FPHS_DB_USER=fphs
    # Connection details for the remote AWS Elaine database for DEV-fphs
    export AWS_DB=ebdb
    export AWS_DB_SCHEMA=ml_app,ipa_ops,persnet,sleep
    export AWS_DB_HOST=fphs-aws-db-dev01.c9dljdsduksr.us-east-1.rds.amazonaws.com
    export AWS_DB_USER=fphs

  fi

  if [ "$EBENV" == 'TEST-aws' ]
  then
    # Connection details for the TEST aws automated processing box
    export ZEUS_DB=zeus
    export ZEUS_FPHS_DB_SCHEMA=ml_app,ipa_ops,sleep
    export ZEUS_FPHS_DB_HOST=aazpl1v3nlxurw.c9dljdsduksr.us-east-1.rds.amazonaws.com
    export ZEUS_FPHS_DB_USER=fphs

    # Connection details for the remote AWS Athena database for DEV-fphs
    export AWS_DB=ebdb
    export AWS_DB_SCHEMA=ml_app,ipa_ops,persnet,sleep
    export AWS_DB_HOST=aazpl1v3nlxurw.c9dljdsduksr.us-east-1.rds.amazonaws.com
    export AWS_DB_USER=fphs

  fi

  if [ "$EBENV" == 'PROD-fphs' ]
  then
    # Connection details for the local FPHS Zeus database for PROD-fphs
    export ZEUS_DB=fphs
    export ZEUS_FPHS_DB_SCHEMA=ml_app
    export ZEUS_FPHS_DB_HOST=fphs-db-prod01
    export ZEUS_FPHS_DB_USER=fphsetl
    # Connection details for the remote AWS Elaine database for PROD-fphs
    export AWS_DB=fphs
    export AWS_DB_SCHEMA=ml_app,ipa_ops,persnet,sleep
    export AWS_DB_HOST=fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com
    export AWS_DB_USER=fphsetl
  fi
fi

if [ -z "$ZEUS_DB" ]
then
  echo "No matching environment"
  exit 1
fi
