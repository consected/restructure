#! /usr/bin/env ruby
# Requires python
# pip install aws-mfa-login
# and aws cli
# The ~/.aws/config and ~/.aws/credentials should be set up with the appropriate
# details.
# Run with
#   AWS_PROFILE=<profile name> AWS_ACCT_ID=<account id> app-scripts/aws_mfa_set.rb
# Copy the exports into your shell

fn = ENV['output_filename']

aml = `which aws-mfa-login`
`pip install aws-mfa-login` if !aml || aml == ''

envs = {}
aws_profile = ENV['AWS_PROFILE']
aws_acct = ENV['AWS_ACCT_ID']

res = `aws sts get-caller-identity | grep "#{aws_acct}"`
while res == ''
  puts 'AWS MFA is needed. Enter the one time code and hit enter'
  aws_mfa = gets.chomp

  res = `aws-mfa-login --profile #{aws_profile} --token #{aws_mfa}`
  res.gsub('export ', '').gsub("\n", '').split(';').each do |i|
    items = i.split('=', 2)
    envs[items[0]] = items[1]
    ENV[items[0]] = items[1]
  end

  res = `aws sts get-caller-identity | grep "#{aws_acct}"`
end

if envs.length > 0
  output = "# now run the following code on the command line\n"
  output += envs.map { |e, f| "export #{e}='#{f}'" }.join("\n")
else
  output = '# already authenticated'
end

if fn
  File.open(fn, 'wb+') do |f|
    f.write output
  end
else
  puts output
end
