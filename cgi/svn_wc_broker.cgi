#!/usr/bin/env ruby 
# vim:encoding=UTF-8
#
# Copyright (c) 2010 David Wright
#
# You are free to modify and use this file under the terms of the GNU LGPL.
# You should have received a copy of the LGPL along with this file.
#
# Alternatively, you can find the latest version of the LGPL here:
#
#      http://www.gnu.org/licenses/lgpl.txt
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

begin; require 'rubygems'; rescue LoadError; end
require 'cgi'
require 'json'
require 'fileutils'
require 'svn_wc_broker'

CONF_FILE = nil

cgi = CGI.new(:encoding => 'UTF-8')

print cgi.header('type' => 'application/x-javascript', 'charset' => 'UTF-8')

include SvnWcBroker

# emergency debug only!
#File.open('/tmp/DEBUG2', 'w') { |f| f.write(cgi.params.inspect) }

# this cgi file *should* be as simple as this now
set_conf_file(CONF_FILE)
print handle_responses(cgi.params).to_json 

