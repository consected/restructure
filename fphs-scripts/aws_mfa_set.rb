#! /usr/bin/env ruby

envs = {}
aws_profile = 'fphsuser'

res = `aws sts get-caller-identity | grep "756598248234"`
while res == ''
  puts "AWS MFA is needed. Enter the one time code and hit enter"
  aws_mfa = gets.chomp

  res = `aws-mfa-login --profile #{aws_profile} --token #{aws_mfa}`
  res.gsub('export ', '').gsub("\n", '').split(";").each do |i|
    items = i.split('=', 2)
    envs[items[0]] = items[1]
    ENV[items[0]] = items[1]
  end

  res = `aws sts get-caller-identity | grep "756598248234"`
end
puts 'now run the following code on the command line'
puts envs.map {|e,f| "export #{e}='#{f}'"}.join("\n")
