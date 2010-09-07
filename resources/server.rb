#!/usr/bin/ruby

# A very simple script to use Potlatch2 locally
# without having to install a rails_port. 
# Run this script on a console, then visit
# http://yourmachinename:3333/potlatch2.html
#
# Note that for *very* stupid flash-player reasons
# neither 127.0.0.1 nor any other IP nor localhost 
# will work. Add a hostname to your /etc/hosts if
# needs be.

require 'webrick'
include WEBrick

s=HTTPServer.new(:Port => 3333, :DocumentRoot => Dir.pwd, :MaxClients => 1000)

# Handle signals.
%w(INT TERM).each do |signal|
  trap(signal) { s.shutdown }
end

s.start
