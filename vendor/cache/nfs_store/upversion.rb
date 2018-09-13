#!/usr/bin/env ruby
require '../nfs_store/lib/nfs_store/version.rb'
v_parts = NfsStore::VERSION.split('.')
oldver = NfsStore::VERSION
v_parts[-1] = v_parts.last.to_i + 1
newver = v_parts.join('.')

t =<<EOF
module NfsStore
  VERSION = "#{newver}"
end
EOF
File.write('../nfs_store/lib/nfs_store/version.rb', t)
puts "Upversioned from #{oldver} to #{newver}"
