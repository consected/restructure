#!/usr/bin/env ruby

require 'json'
res = `/opt/elasticbeanstalk/bin/get-config environment`
envvars = JSON.parse(res)
envvars.each { |k, v| puts "export #{k}=\"#{v}\"" }
