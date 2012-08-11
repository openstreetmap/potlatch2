#!/bin/sh

# A very simple script to use Potlatch2 locally
# Run this script on a console, then visit
# http://yourmachinename:3333/potlatch2.html
#
# Note that for *very* stupid flash-player reasons
# neither 127.0.0.1 nor any other IP nor localhost 
# may not work. Add a hostname to your /etc/hosts if
# needs be.

python -m SimpleHTTPServer 3333
