# Get the AWS environment variables if we are in an AWS elastic beanstalk environment
if [ -f /opt/elasticbeanstalk/bin/get-config ]; then
  export $(/opt/elasticbeanstalk/bin/get-config --output YAML environment | sed -r 's/: /=/' | xargs)
  export EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
  export AWS_DEFAULT_REGION="$(echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//')"
  export AWS_REGION=${AWS_DEFAULT_REGION}
fi
