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

require 'svn_wc'

#
# receives method/action requests from web app (AJAX) returns data in expected format
# is just a 'simple' client of ruby gem lib 'svn_wc'
#
# returned data is generally a array of anonymous hashes containing
# svn entries info, or errors.
#
# e.g.
#    each_details           = {}
#    each_details[:file]    = path
#    each_details[:status]  = status
#    each_details[:content] = content
#    each_details[:entries] = entries_list
#    each_details[:error]   = error
#    each_details[:repo_root_local_path]  = File.join(@repo_root, '/')
#
module SvnRepoClient
  STATUS_SPACER = "\t" # swt.js (js/jqtree file uses this)

  @@svn_wc = SvnWc::RepoAccess.new

  # getter for repo root
  def repo_root ; @@svn_wc.svn_repo_working_copy ; end

  # if conf file exists and have a working copy of the repo, return the path
  # to it, otherwise create it (do a checkout, not forced)
  # set force_checkout = true to force a checkout
  # returns svn_repo_working_copy abs_path
  def get_repo
    if File.file? @conf_file
      @@svn_wc.set_conf @conf_file
    else raise ArgumentError, "config file not found! #{@conf_file}" end

    #if not File.directory? @@svn_wc.svn_repo_working_copy
    begin
      if not File.directory? @@svn_wc.svn_repo_working_copy \
         or @@svn_wc.force_checkout
        #@@svn_wc.do_checkout(true, @@svn_wc.force_checkout)
        @@svn_wc.do_checkout(true)
      end
    rescue SvnWc::RepoAccessError => e
       raise e.message
    end
    @repo_root = @@svn_wc.svn_repo_working_copy
  end

  def svn_status(f_regex=nil, f_amt=nil, dir=@repo_root)
      get_repo
      repo_entries = Array.new
      begin
        l_svn_list = Array.new
        @@svn_wc.status(dir).each { |el|
          status_info = {}
          #status_info[:last_changed_rev] = el[:last_changed_rev]
          status_info[:status] = el[:status]
          status_info[:error] = ''
          status_info[:entry_name] = el[:path]
          #if File.directory?(File.join(@repo_root, el[:path]))
          if File.directory?(File.join(dir, el[:path]))
            status_info[:kind] = 2 # is dir
          else
            status_info[:kind] = 1 # is 'file'
          end
          #apply filter - limit result set with filter
          #f_regex, f_amt = 'cof/htdocs/template', 10
          if f_regex.nil?
           l_svn_list.push status_info
          elsif el[:path].match(f_regex)
           l_svn_list.push status_info
          end
          #l_svn_list.push status_info
          if f_amt.nil? or f_amt.empty?
          elsif l_svn_list.size > f_amt.to_i
            break
          end
        }

        @entries_list = _to_expected_json_format(l_svn_list)
        repo_entries.push info_data
      rescue SvnWc::RepoAccessError => e
        #@error = e.message
        @error = "#{e.message} #{@@svn_wc}"
        repo_entries.push info_data
      end
      repo_entries
  end

 
  # diff current to previous (HEAD only)
  # returns diff content
  def svn_diff
     file_list_diffs = Array.new
     @files.each { |f_list_str|
       f_stat, f_name = f_list_str.split(/\s/)
       begin
         get_repo
         @path = f_name
         @content = @@svn_wc.diff(f_name).to_s
         @status = f_stat
         file_list_diffs.push info_data
       rescue SvnWc::RepoAccessError => e
         @error = e.message
         file_list_diffs.push info_data
       end
     }

     file_list_diffs
  end

  # commit, return message and revision, committed file list
  def svn_commit
      get_repo
      rev = Array.new
      begin
        @content = "Committed. Revision: #{@@svn_wc.commit(@files)}
                                  Files:
                                  #{@files.join("\n")}"
        rev.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        rev.push info_data
      end
      rev
  end

  # add, returns 'added' message and added file list
  def svn_add
      get_repo
      rev = Array.new
      begin
        @content = "Added. #{@@svn_wc.add(@files).to_a.join("\n")}"
        rev.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        rev.push info_data
      end
      rev
  end

  # update, returns 'updated' message, revision and update data
  def svn_update
      get_repo
      remote_files = Array.new
      begin
        @content = "Updated: Revision #{@@svn_wc.update.to_a.join("\n")}"
        remote_files.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        remote_files.push info_data
      end
      remote_files
  end

  # delete
  def svn_delete
      get_repo
      rev = Array.new
      begin
        @content = "Deleted. #{@@svn_wc.delete(@files).to_a.join("\n")}"
        rev.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        rev.push info_data
      end
      rev
  end

  # info, returns 'updated' message, revision and update data
  def svn_info
      get_repo
      infos = Array.new
      begin
        @content = "Info: #{@@svn_wc.info(@files)[:url]}"
        infos.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        infos.push info_data
      end
      infos
  end

  # revert, returns message
  def svn_revert
      get_repo
      infos = Array.new
      begin
        @content = "Reverted: #{@@svn_wc.revert(@files)}
                                  Files:
                                  #{@files.join("\n")}"
        infos.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        infos.push info_data
      end
      infos
  end


  # ignore, returns 'added' message and added file list
  def svn_ignore
      get_repo
      rev = Array.new
      begin
        cmd = @@svn_wc.propset('ignore', @files, @repo_root)
        #@content = "Ignoring. #{cmd} #{@files.to_a.join("\n")}"
        @content = "Ignoring. #{cmd}"
        rev.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        rev.push info_data
      end
      rev
  end


  # recursively list entries, provides file or dir info and access to 
  # nice repo/file info
  def svn_list(f_regex=nil, f_amt=nil, dir=@repo_root)
      get_repo
      repo_entries = Array.new
      begin
        l_svn_list = Array.new
        @@svn_wc.list(dir).each { |el|
          status_info = {}
          #fqpn = File.join(@repo_root, el[:entry])
          fqpn = File.join(dir, el[:entry])
          #status_info[:last_changed_rev] = el[:last_changed_rev]
          status_info[:entry_name] = fqpn
          status_info[:status] = ' '
          if File.directory? fqpn
            status_info[:kind] = 2 # is dir
          else
            status_info[:kind] = 1 # is 'file'
          end
          #apply filter - limit result set with filter
          #f_regex, f_amt = 'cof/htdocs/template', 10
          if f_regex.nil?
           l_svn_list.push status_info
          elsif el[:entry].match(f_regex)
           l_svn_list.push status_info
          end
          #l_svn_list.push status_info
          if f_amt.nil? or f_amt.empty?
          elsif l_svn_list.size > f_amt.to_i
            break
          end
        }
        #@entries_list = l_svn_list
        @entries_list = _to_expected_json_format(l_svn_list)
        repo_entries.push info_data
      rescue SvnWc::RepoAccessError => e
        @error = e.message
        repo_entries.push info_data
      end
      repo_entries
  end

  def _collect_and_group(file_info_list)

    entries_group_by_dir = {}
    file_info_list.each do |el|
      en = el[:entry_name]
      if el[:kind] == 2
        entries_group_by_dir[en] = [] unless entries_group_by_dir[en]
        entries_group_by_dir[en].push en
      elsif el[:kind] == 1
        entries_group_by_dir[File.dirname(en)] = [] unless entries_group_by_dir[File.dirname(en)] 
        entries_group_by_dir[File.dirname(en)].push "#{en}:#{el[:status]}"
      end
    end

    entries_group_by_dir
  end

  def _to_expected_json_format(file_info_list)
    require 'enumerator' # to_enum :each_with_index

    entries_group_by_dir = _collect_and_group(file_info_list)

    entries_formatted = {}
    entries_formatted[:children] = []
    atts = {}
    atts[:id] = ''
    c_entries = {}
    c_entries[:attributes] = atts
    c_entries[:data] = ''
    entries = []
    id = 0
    entries_group_by_dir.each do |k|
      entries_formatted[:state] = 'open'
      entries_formatted[:data] = k[0]
      entries_formatted[:children] = k[1].to_enum(:each_with_index).collect{|x,i|
        next unless x and x.split(':')[1]
        {:attributes => {:id => i}, :data => x.split(':')[1] + STATUS_SPACER + x.split(':')[0]}
      }
      entries.push entries_formatted
      entries_formatted = {}
      c_entries = {}
    end

    entries
    
  end

  def info_data
    each_details           = Hash.new
    each_details[:file]    = @path
    each_details[:status]  = @status
    each_details[:content] = @content
    #each_details[:rev]     = rev
    # entries_list expects an array of anon hash's
    each_details[:entries] = @entries_list
    each_details[:error]   = @error
    each_details[:repo_root_local_path]  = File.join(@repo_root, '/')

    # high level repo details
    each_details[:svn_repo_master] = @@svn_wc.svn_repo_master
    each_details[:svn_user]        = @@svn_wc.svn_user
    #each_details[:svn_pass]        = @@svn_wc.svn_pass
    each_details[:svn_repo_config_file] = @@svn_wc.svn_repo_config_file

    each_details
  end

end

if __FILE__ == $0 
   @conf_file = '/home/httpd/radmin/config/svn_conf.yaml' 
   #p SvnRepoClient::svn_list
   #p svn_list
   #p svn_list
   #p Object.new.extend(self).svn_list

   class Object
   require 'fileutils'
   require 'svn_wc_client'
   include SvnRepoClient
   #svn_list
   end
   #p eval("svn_list") 
   p svn_list
   #p SvnRepoClient::svn_list
   #p Tester.new.svn_list


end

