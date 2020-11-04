#!/usr/bin/env ruby
# frozen_string_literal: true

VERSION_FILE = ENV['VERSION_FILE'] || 'version.txt'
v = File.read(VERSION_FILE)
vs = v.strip.split('.')
vs[2] = vs[2].to_i + 1
newver = vs.join('.')
File.open(VERSION_FILE, 'w') { |f| f.write newver } unless ARGV.include?('-p')
puts newver
