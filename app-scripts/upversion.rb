#!/usr/bin/env ruby
# frozen_string_literal: true

VERSION_FILE = ENV['VERSION_FILE'] || 'version.txt'
v = File.read(VERSION_FILE)
vs = v.strip.split('.')
if ARGV.include?('minor')
  # Update the minor version and leave off the patch version
  # e.g. 3.47.89 becomes 3.48
  vs.delete_at(2)
  vs[1] = vs[1].to_i + 1
elsif vs[2].nil?
  # Set the first patch version to zero
  vs[2] = 0
else
  # Increment patch version
  vs[2] = vs[2].to_i + 1
end
newver = vs.join('.')
File.open(VERSION_FILE, 'w') { |f| f.write newver } unless ARGV.include?('-p')
puts newver
