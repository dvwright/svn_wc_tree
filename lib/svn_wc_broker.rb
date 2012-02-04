# vim:fileencoding=UTF-8
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

require 'fileutils'
require 'svn_wc_client'

#XXX/TODO docs;tests
#
# Broker requests between web app (AJAX) to svn_wc_client
#
# (this script is probably unnecessary and can be done away with
# it's left over from an early design decision which has changed)
# 
# what it does: populate the top level array element with :run_error
# set to any exception that occurs: #repo[0]={:run_error => "Error: #{e.message}"}
#
module SvnWcBroker

  # any action we want to support gets added to this list
  #--
  # this list gets 'evaled' is why
  #++
  SUPPORTED_ACTIONS = %w(add commit delete info 
                         revert list ignore diff update 
                         status)

  # set abs_path to your configuration file
  def set_conf_file(conf) ; @conf_file = conf ; end

  # makes the requests against our lib which, uses the ruby gem lib 'svn_wc'
  include SvnRepoClient

  # pass web requests in, handle defined actions, return results
  # params can be a cgi request object, or a rails request object, whatever
  # contains our web POST request
  def handle_responses(params)

      #--
      # to debug during devel
      #return svn_results debug_request(params['do_svn_action'])
      #return svn_results debug_request(params.to_s.to_a)
      #++
      if params['do_svn_action'] \
         && (params['do_svn_action'].to_s == 'Do Svn Action')
      
        #return svn_results debug_request(params)
        if params and params['svn_action'].to_s.strip.empty?
          return svn_results 
        else
          return svn_results( send(:do_requested_action, params) )
        end

      else 
        return svn_results
      end

  end

  def debug_request(message)
    resp_data = Array.new
    resp_data[0] = {:run_error => "Debug: #{message}"}
  end

  def do_requested_action(params)
    resp_data = Array.new

    action = params['svn_action'].to_s.strip.downcase
    files  = params['svn_files']
    @dir   = params['dir']

    begin
      if files and files.to_a.size > 0
        files_striped = ret_just_files_list(
                           process_params_to_list_of_files(files.to_s))
        @files = files_striped.to_a.uniq
        #@files.uniq
        #return svn_results debug_request(@files)

        # diff need status info
        if ('diff' == action ) 
           @files = process_params_to_list_of_files(files.to_s).to_a.uniq
        end

      end
      # eval known actions only
      # svn_list takes args # svn_status takes args
      if action == 'list' || action == 'status' 
        eval("svn_#{action}('#{params['filter_re']}','#{params['filter_amt']}','#{params['dir']}')")
      else
        # NOTE only eval known supported actions
        eval("svn_#{action}") if SUPPORTED_ACTIONS.index(action)
      end
    rescue Exception => exn
      resp_data[0] = {:run_error => "Error: #{exn.message}"}
    end

  end

  # default action, always return the status list
  def get_status_list
    svn_status_list = Array.new
    run_error = String.new
  
    begin
      svn_status_list = svn_status(params['filter_re'], params['filter_amt'], params['dir'])
    rescue Exception => e
      run_error <<  e.message
    end
  
    ##if svn_status_list.empty? or svn_status_list.size == 1
    ##if svn_status_list.empty?
    #if @entries_list[0][:entry_name].nil?
    #  svn_status_list[0] = {:repo_status => 'upto date',
    #                        :repo_root_local_path  => repo_root}
    #end
    
    if run_error.length > 0 
      svn_status_list[0] = {:run_error => run_error} 
    end
  
    svn_status_list
  end
  
  # svn_wc_broker always returns results, data if set, otherwise svn status list
  def svn_results(data=[])
     if data.empty? then get_status_list else data end
  end
  
  # clean up POST requests
  def process_params_to_list_of_files(passed_file_list) # :nodoc:
      if passed_file_list and passed_file_list.match(/,/)
        passed_file_list = passed_file_list.split(/,/).to_a
      end
  
      passed_file_list_cleaned = Array.new
      passed_file_list.each do |f_list_str|
        # cgi params cleanup
        # i.e. substituting the cgi with another 'http request broker'
        #f_list_str.gsub!(/((\302\240)+|\t+|\s+)/, "\s")#&nbsp; becomes odd 2 byte char
        f_list_str.gsub!(/((\302\240)+|\t+|\s+)/, "\s")#&nbsp; becomes odd 2 byte char
        passed_file_list_cleaned.push f_list_str
      end
      passed_file_list_cleaned
  end
  
  def ret_just_files_list(file_status_list) # :nodoc:
    just_files = Array.new
    return file_status_list unless file_status_list.respond_to?('each')
    file_status_list.each do |f_list_str|
      f_stat, f_name = f_list_str.split(/\s/)
      just_files.push(f_name)
    end
    just_files
  end
  
end
 
