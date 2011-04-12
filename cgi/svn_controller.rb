begin; require 'rubygems'; rescue LoadError; end
#require 'json'
require 'fileutils'
require 'svn_wc_broker'

class SvnController < ApplicationController

  before_filter :session_required

  include SvnWcBroker

  def index
    @title = 'Svn Admin'
    @conf_file = '/home/httpd/radmin/config/svn_conf.yaml'
    #@conf_file = '/tmp/sc.yaml'

    flash[:notice] = 'Must Select A Partner From List'

    if request.get? then render :template => 'svn/index' and return false end
    #if request.get? 
    # render :file => "#{RAILS_ROOT}/public/test.html" and return false 
    #end

    if request.post?
     set_conf_file(@conf_file)
     render :json => handle_responses(params) and return false
    end

  end

end
