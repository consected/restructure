#! /usr/bin/env ruby
# Requires python
# pip install aws-mfa-login
# and aws cli

fn = ENV['output_filename']

aml = `which aws-mfa-login`
if !aml || aml == ''
  `pip install aws-mfa-login`
end

envs = {}
aws_profile = 'fphsuser'
aws_acct = '756598248234'

res = `aws sts get-caller-identity | grep "#{aws_acct}"`
while res == ''
  puts "# AWS MFA is needed. Enter the one time code and hit enter"
  aws_mfa = gets.chomp

  res = `aws-mfa-login --profile #{aws_profile} --token #{aws_mfa}`
  res.gsub('export ', '').gsub("\n", '').split(";").each do |i|
    items = i.split('=', 2)
    envs[items[0]] = items[1]
    ENV[items[0]] = items[1]
  end

  res = `aws sts get-caller-identity | grep "#{aws_acct}"`
end

if envs.length > 0
  output = "# now run the following code on the command line\n"
  output += envs.map {|e,f| "export #{e}='#{f}'"}.join("\n")
else
  output = "# already authenticated"
end

if fn
  File.open(fn, 'wb+') do |f|
    f.write output
  end
else
  puts output
end
