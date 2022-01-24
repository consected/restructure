# Get the AWS environment variables if we are in an AWS elastic beanstalk environment
if [ -f /opt/elasticbeanstalk/bin/get-config ]; then
  export $(/opt/elasticbeanstalk/bin/get-config --output YAML environment | sed -r 's/: /=/' | xargs)
fi
