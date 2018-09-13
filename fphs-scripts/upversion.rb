#!/usr/bin/env ruby
VERSION_FILE = 'version.txt'
v = File.read(VERSION_FILE)
vs = v.strip.split('.')
vs[2] = vs[2].to_i + 1
newver = vs.join('.')
File.open(VERSION_FILE, 'w') { |f|  f.write newver }
puts newver
