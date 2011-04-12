# Copyright (c) 2009 David Wright
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

#begin; require 'rubygems'; rescue LoadError; end
#require 'svn_wc_broker'
require 'svn_wc'
require File.join(File.dirname(__FILE__), "..", "lib", 'svn_wc_broker')
require 'test/unit'
require 'fileutils'
require 'tempfile'
require 'time'
require 'json'
require 'yaml'
require 'cgi'


# unit tests to prove module SvnWc/class SvnAccess functionality.
class TestSvnWc < Test::Unit::TestCase

  include SvnWcBroker

  def setup
    @yconf = {
      "force_checkout"        => true,
      "svn_repo_master"       => "file://#{Dir.mktmpdir('R')}",
      "svn_repo_working_copy" => "#{Dir.mktmpdir('F')}",
      "svn_repo_config_path"  => File.join(File.dirname(\
                                            File.dirname(File.expand_path(__FILE__))))
    }
    sys_create_repo
    write_conf_file
  end

  def write_conf_file
    @conf = File.join(Dir.tmpdir, 'conf_file.yaml')
    File.open( @conf, 'w' ) { |out| YAML.dump(@yconf, out) }
  end
  
  def sys_create_repo
    begin
      svnadmin =`which svnadmin`
      svn      =`which svn`
    rescue
      puts 'svn/svnadmin do not seem to be installed, Please install svn/svnadmin'
      exit 1
    end
    @svn_r_m = @yconf['svn_repo_master'].gsub(/file:\/\//, '')
    `"#{svnadmin.chomp}" create "#{@svn_r_m}"`
    `cd "#{@yconf['svn_repo_working_copy']}" && "#{svn.chomp}" co "#{@yconf['svn_repo_master']}"`

    @wc_repo2 = Dir.mktmpdir('E')
  end

  def teardown
   # remove working copy of repo
   FileUtils.remove_entry_secure @yconf['svn_repo_working_copy']
   FileUtils.remove_entry_secure @wc_repo2
   FileUtils.remove_entry_secure @svn_r_m
  end
  
  def test_no_force_conf_param_no_checkout
    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    yconf = @yconf
    yconf['force_checkout'] = false

    conf = File.join(Dir.tmpdir, 'tmp_conf_file.yaml')
    File.open(conf, 'w') { |out| YAML.dump(yconf, out) }

    set_conf_file(conf)
    res = handle_responses(params)
    assert res[0][:error].match(/status check Failed:/)
    assert res[0][:error].match(/is not a working copy/)
    assert res[0][:error].match(/Svn::Error::WcNotDirectory/)
    assert res[0][:error].match(/SvnWc::RepoAccess/)
  end

  def test_force_conf_param_checkout
    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    set_conf_file(@conf)
    res = handle_responses(params)
    #p res
    assert_nil res[0][:svn_user]
    assert_nil res[0][:status]
    assert_nil res[0][:file]
    assert_nil res[0][:entries]
    assert_nil res[0][:content]
    assert_equal @yconf["svn_repo_working_copy"], res[0][:repo_root_local_path].chop('/')
    assert_equal @yconf["svn_repo_master"], res[0][:svn_repo_master]
    assert_equal res[0][:svn_repo_config_file], @conf
    assert_equal @yconf['svn_repo_working_copy'], res[0][:entries][0][:dir_name]
    assert_equal 2, res[0][:entries][0][:kind]
  end


  def test_can_load_passed_conf
    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    #params['svn_action']
    #params['svn_files']
    set_conf_file(@conf)
    res = handle_responses(params)
    assert_nil res[0][:svn_user]
    assert_nil res[0][:status]
    assert_nil res[0][:file]
    assert_nil res[0][:entries]
    assert_nil res[0][:content]
    assert_equal @yconf["svn_repo_working_copy"], res[0][:repo_root_local_path].chop('/')
    assert_equal @yconf["svn_repo_master"], res[0][:svn_repo_master]
    assert_equal res[0][:svn_repo_config_file], @conf
    assert res[0][:error].match 'status check Failed'
    assert res[0][:error].match 'not a working copy'
  end

  def test_add_commit_with_default_response_list_entries

    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)

    f = []
    (1..4).each { |d|
      FileUtils.mkdir @yconf['svn_repo_working_copy'] + "/dir#{d}"
      f[d] = @yconf['svn_repo_working_copy']+ "/dir#{d}/test_#{Time.now.usec.to_s}.txt"
      FileUtils.touch f[d]
    }
    #p File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])
    svn.add [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])]

    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    #params['svn_action']
    #params['svn_files']
    set_conf_file(@conf)
    res = handle_responses(params).sort
    #p res
    # top level json response
    assert_equal @yconf["svn_repo_working_copy"], res[0][:repo_root_local_path].chop('/')
    assert_equal @yconf["svn_repo_master"], res[0][:svn_repo_master]
    assert_equal res[0][:svn_repo_config_file], @conf
    assert_nil res[0][:status]
    assert_nil res[0][:file]
    assert_nil res[0][:error]
    assert_nil res[0][:content]
    # 'per record' json reponse
    #res[0][:entries][0].each do |rec| end
    assert_equal 'A',  res[0][:entries][0][:status]
    assert_equal f[1], res[0][:entries][0][:entry_name]
    assert_equal 1,    res[0][:entries][0][:kind]
    assert_equal '',   res[0][:entries][0][:error]
    # 2nd entry
    assert_equal 'A',  res[0][:entries][1][:status]
    assert_equal File.dirname(f[1]), res[0][:entries][1][:entry_name]
    # a dir, but just another entry to svn (type 2, dir is for something
    # else?)
    # bug? this should be a dir
    assert_equal 1, res[0][:entries][1][:kind]
    assert_equal '',res[0][:entries][1][:error]
    # 3rd entry
    assert_equal 'A', res[0][:entries][2][:status]
    assert_equal f[2], res[0][:entries][2][:entry_name]
    assert_equal 1, res[0][:entries][2][:kind]
    assert_equal '',res[0][:entries][2][:error]
    # 4th entry
    assert_equal 'A', res[0][:entries][3][:status]
    assert_equal File.dirname(f[2]), res[0][:entries][3][:entry_name]
    assert_equal 1, res[0][:entries][3][:kind]
    assert_equal '',res[0][:entries][3][:error]
    # 5th entry - unknown to svn (not added)
    assert_equal '?', res[0][:entries][4][:status]
    assert_equal File.dirname(f[3]), res[0][:entries][4][:entry_name]
    assert_equal 1, res[0][:entries][4][:kind]
    assert_equal '',res[0][:entries][4][:error]
    # 6th entry
    assert_equal 'A',  res[0][:entries][5][:status]
    assert_equal f[4], res[0][:entries][5][:entry_name]
    assert_equal 1, res[0][:entries][5][:kind]
    assert_equal '',res[0][:entries][5][:error]
    # 7th entry
    assert_equal 'A',  res[0][:entries][6][:status]
    assert_equal File.dirname(f[4]), res[0][:entries][6][:entry_name]
    assert_equal 1, res[0][:entries][6][:kind]
    assert_equal '',res[0][:entries][6][:error]
    # 8th entry - the 'root' dir
    assert_equal @yconf['svn_repo_working_copy'], res[0][:entries][7][:dir_name]
    assert_equal 2, res[0][:entries][7][:kind]
    assert_nil res[0][:entries][7][:status]
    assert_nil res[0][:entries][7][:error]
    assert_nil res[0][:entries][7][:entry_name]
       
    # now commit
    rev = svn.commit [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4]), f[1], f[2], f[4]]
    assert rev >= 1
    res = handle_responses(params).sort
    #p res
    # after commit, list only show files, svn does NOT know about
    # top level json response
    assert_equal '?',  res[0][:entries][0][:status]
    assert_equal File.dirname(f[3]), res[0][:entries][0][:entry_name]
    assert_equal 1,    res[0][:entries][0][:kind]
    assert_equal '',   res[0][:entries][0][:error]
    # 2nd entry - the 'root' dir
    assert_equal @yconf['svn_repo_working_copy'], res[0][:entries][1][:dir_name]
    assert_equal 2, res[0][:entries][1][:kind]
    assert_nil res[0][:entries][1][:status]
    assert_nil res[0][:entries][1][:error]
    assert_nil res[0][:entries][1][:entry_name]
    # no 3rd entry
    assert_nil res[0][:entries][2]
 
  end
  
  def test_errors_if_cant_checkout_repo_to_local
    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    FileUtils.chmod 0000, @yconf['svn_repo_working_copy']
    set_conf_file(@conf)
    res = handle_responses(params)
    #p `ls -dl #{@yconf['svn_repo_working_copy']}`
    #p res
    assert res[0][:error].match(/status check Failed:/)
    assert res[0][:error].match(/Can't open file/)
    assert res[0][:error].match(/Permission denied/)
    assert res[0][:error].match(/SvnWc::RepoAccess/)

    FileUtils.chmod 0100, @yconf['svn_repo_working_copy']
    set_conf_file(@conf)
    res = handle_responses(params)
    assert res[0][:error].match(/status check Failed:/)
    assert res[0][:error].match(/is not a working copy/)
    assert res[0][:error].match(/Svn::Error::WcNotDirectory/)
    assert res[0][:error].match(/SvnWc::RepoAccess/)

    sleep 1
    # perms needed to cleanup in teardown
    FileUtils.chmod 0755, @yconf['svn_repo_working_copy'] 
  end

  def test_can_get_svn_info
    params = Hash.new
    params['do_svn_action'] = 'Do Svn Action'
    params['svn_action'] = 'info'
    #params['svn_files']
    set_conf_file(@conf)
    res = handle_responses(params)
    p res
    #assert_nil res[0][:svn_user]
    #assert_nil res[0][:status]
    #assert_nil res[0][:file]
    #assert_nil res[0][:entries]
    #assert_nil res[0][:content]
    #assert_equal @yconf["svn_repo_working_copy"], res[0][:repo_root_local_path].chop('/')
    #assert_equal @yconf["svn_repo_master"], res[0][:svn_repo_master]
    #assert_equal res[0][:svn_repo_config_file], @conf
    #assert res[0][:error].match 'status check Failed'
    #assert res[0][:error].match 'not a working copy'

  end

  def TODO_test_add_new_dir_and_file_and_commit_and_delete
    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)
    file = new_unique_file_in_repo_root
    begin
      svn.info(file)
      fail 'file not in svn'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not under version control/)
    end
    svn.add file
    rev = svn.commit file
    assert rev >= 1
    svn.delete file
    # commit our delete
    n_rev = svn.commit file
    assert_equal rev+1, n_rev
  end

  def TODO_test_add_and_commit_several_select_new_dirs_and_files_then_svn_delete

    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)

    f = []
    (1..4).each { |d|
      FileUtils.mkdir @yconf['svn_repo_working_copy'] + "/dir#{d}"
      f[d] = @yconf['svn_repo_working_copy']+ "/dir#{d}/test_#{Time.now.usec.to_s}.txt"
      FileUtils.touch f[d]
    }

    begin
      svn.info(f[1])
      fail 'is not under version control'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not a working copy/)
    end
    svn.add [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])]
    rev = svn.commit [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4]), f[1], f[2], f[4]]
    assert rev >= 1

    begin
      svn.info(f[3])
      fail 'is not under version control'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not a working copy/)
    end
    assert_equal File.basename(f[4]), File.basename(svn.info(f[4])[:url])

    svn.delete([f[1], f[2], f[4], File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])])
    n_rev = svn.commit [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4]), f[1], f[2], f[4]]
    assert_equal rev+1, n_rev

    assert ! File.file?(f[4])
    assert File.file? f[3]
    assert FileUtils.rm_rf(File.dirname(f[3]))
  end

  #def test_add_commit_new_dirs_files_then_svn_delete_methods_default_to_repo

  #  svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true)

  #  f = []
  #  (1..4).each { |d|
  #    FileUtils.mkdir @yconf['svn_repo_working_copy'] + "/dir#{d}"
  #    f[d] = @yconf['svn_repo_working_copy']+ "/dir#{d}/test_#{Time.now.usec.to_s}.txt"
  #    FileUtils.touch f[d]
  #  }

  #  begin
  #    svn.info(f[1])
  #    fail 'is not under version control'
  #  rescue SvnWc::RepoAccessError => e
  #    assert e.message.match(/is not a working copy/)
  #  end
  #  svn.add [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])]
  #  rev = svn.commit [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4]), f[1], f[2], f[4]]
  #  assert rev >= 1

  #  begin
  #    svn.info(f[3])
  #    fail 'is not under version control'
  #  rescue SvnWc::RepoAccessError => e
  #    assert e.message.match(/is not a working copy/)
  #  end
  #  assert_equal File.basename(f[4]), File.basename(svn.info(f[4])[:url])

  #  svn.delete([f[1], f[2], f[4], File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4])])
  #  n_rev = svn.commit [File.dirname(f[1]), File.dirname(f[2]), File.dirname(f[4]), f[1], f[2], f[4]]
  #  assert_equal rev+1, n_rev

  #  assert ! File.file?(f[4])
  #  assert File.file? f[3]
  #  assert FileUtils.rm_rf(File.dirname(f[3]))
  #end

  def TODO_test_add_commit_update_file_status_revision_modify_diff_revert
    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)
    f = new_unique_file_in_repo_root
    #p svn.list_entries
    svn.add f
    start_rev = svn.commit f
    #p start_rev
    #svn.up f
    #p svn.info(f)
    #p svn.status(f)
    #add text to f
    File.open(f, 'a') {|fl| fl.write('adding this to file.')}
    #p svn.status(f)
    # M == modified
    assert_equal 'M', svn.status(f)[0][:status]
    assert_equal start_rev, svn.info(f)[:rev] 

    assert svn.diff(f).to_s.match('adding this to file.')

    svn.revert f
    assert_equal svn.commit(f), -1
    assert_equal [start_rev, []], svn.up(f)
    assert_equal start_rev, svn.info(f)[:rev] 
    assert_equal Array.new, svn.diff(f)
  end

  ## TODO
  #def test_add_does_recursive_nested_dirs
  #  svn = SvnWc::RepoAccess.new(nil, true)

  #  # add 1 new file in nested heirerarcy
  #  # TODO ability to add recursive nested dirs
  #  FileUtils.mkdir_p @yconf['svn_repo_working_copy'] + "/d1/d2/d3"
  #  nested = @yconf['svn_repo_working_copy'] +
  #                    "/d1/d2/d3/test_#{Time.now.usec.to_s}.txt"
  #  FileUtils.touch nested
  #  svn.add nested

  #  svn.status.each { |ef|
  #    next unless ef[:entry_name].match /test_.*/
  #    assert_equal 'A', ef[:status]
  #    assert_equal nested, File.join(@yconf['svn_repo_working_copy'], ef[:entry_name])
  #  }
  #  svn.revert
  #  assert_equal 1, svn.status.length
  #  assert_equal File.basename(@yconf['svn_repo_working_copy']),
  #                     svn.status[0][:entry_name]
  #end

  def TODO_test_update_acts_on_whole_repo_by_default_knows_a_m_d
    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)
    #p svn.list_entries
    #exit

    rev = svn.info()[:rev]
    assert_equal [rev, []], svn.update

    (rev1, files)  = check_out_new_working_copy_add_and_commit_new_entries(3)
    assert_equal rev+1, rev1

    fe = Array.new
    files.each { |e| fe.push File.basename e}
    assert_equal \
      [(rev + 1), ["A\t#{fe[0]}", "A\t#{fe[1]}", "A\t#{fe[2]}"]],
      svn.update, 'added 3 files into another working copy of the repo, update
                   on current repo finds them, good!'

    # Confirm can do add/delete/modified simultaniously
    # modify, 1 committed file, current repo
    lf = File.join @yconf['svn_repo_working_copy'], fe[0]
    File.open(lf, 'a') {|fl| fl.write('local repo file is modified')}
    # delete, 2 committed file, in another repo
    rev2 \
       = delete_and_commit_files_from_another_working_copy_of_repo(
                                                       [files[1], files[2]]
                                                                  )
    # add 1 file, in another repo
    (rev3, file)  = check_out_new_working_copy_add_and_commit_new_entries
    fe.push File.basename file[0]

    assert_equal \
      [(rev + 3), ["M\t#{fe[0]}", "A\t#{fe[3]}", "D\t#{fe[1]}", "D\t#{fe[2]}"]],
      svn.update, '1 modified locally, 2 deleted in other repo, 1 added other
      repo, update locally, should find all these changes'

  end

  #def test_update_reports_collision
  #  svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)

  #  assert_equal '', svn.update

  #  rev, f_name = check_out_new_working_copy_add_and_commit_new_entries

  #  assert_equal " #{f_name}", svn.update

  #  f = new_unique_file_in_repo_root
  #  modify_file_and_commit_into_another_working_repo(f)
  #  File.open(f, 'a') {|fl| fl.write('adding text to file.')}
  #  # XXX no update done, so this file should clash with
  #  # what is already in the repo
  #  start_rev = svn.commit f
  #  #p svn.status(f)
  #  #assert_equal 'M', svn.status(f)[0][:status]
  #  #assert_equal start_rev, svn.info(f)[:rev] 
  #end

  def TODO_test_list_recursive
    FileUtils.rm_rf @yconf['svn_repo_working_copy']

    if ! File.directory?(@yconf['svn_repo_working_copy'])
      FileUtils.mkdir @yconf['svn_repo_working_copy'] 
    end

    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)

    # how many files does svn status find?
    r_list = []
    svn.list.each { |ef|
      r_list.push File.join(@yconf['svn_repo_working_copy'], ef)
    }

    # not cross platform
    dt = Dir["#{@yconf['svn_repo_working_copy']}/**/*"]
    d_list = []
    dt.each do |item|
      #case File.stat(item).ftype
      d_list.push item
    end

    the_diff = r_list - d_list
    # not cross platform
    assert_equal the_diff, [File.join @yconf['svn_repo_working_copy'], '/']
    #puts the_diff
    #p d_list.length
    #p r_list.length
    assert_equal d_list.length, r_list.length-1

  end

  def TODO_test_status_n_revert_default_to_repo_root
    FileUtils.rm_rf @yconf['svn_repo_working_copy']

    if ! File.directory?(@yconf['svn_repo_working_copy'])
      FileUtils.mkdir @yconf['svn_repo_working_copy'] 
    end

    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)

    puts svn.status
    repo_wc = @yconf['svn_repo_working_copy']

    # add 4 new files in the repo root
    num_create = 4
    add_files = []
    (1..num_create).each { |d|
      fl = new_unique_file_in_repo_root
      svn.add fl
      add_files.push fl
    }
    # add 1 new file in nested heirerarcy
    FileUtils.mkdir_p File.join(repo_wc, 'd1','d2','d3')
    nested = File.join(repo_wc, 'd1','d2','d3',"test_#{Time.now.usec.to_s}.txt")
    FileUtils.touch nested
    # TODO ability to add recursive nested dirs
    #svn.add nested
    svn.add File.join(repo_wc, 'd1') # adding 'root' adds all

    add_files.push File.join(repo_wc, 'd1'), File.join(repo_wc, 'd1', 'd2'),
                    File.join(repo_wc, 'd1', 'd2', 'd3'), nested

    was_added = []
    # XXX status should only return modified/added or unknown files
    svn.status.each { |ef|
      assert_equal 'A', ef[:status]
      was_added.push ef[:path]
    }
    assert_equal add_files.sort, was_added.sort

    svn.revert
    svn.status.each { |ef|
      # files we just reverted are not known to svn now, good
      assert_equal '?', ef[:status]
    }

    svn.status.each { |ef|
      add_files.each { |nt|
        begin
          svn.info nt
          flunk 'svn should not know this file'
        rescue
          assert true
        end
      }
    }

    #clean up
    add_files.each {|e1| FileUtils.rm_rf e1 }

  end

  def TODO_test_commit_file_not_yet_added_to_svn_raises_exception
    svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true, true)
    file = new_unique_file_in_repo_root
    fails = false
    begin
      svn.commit file
    rescue SvnWc::RepoAccessError => e
      assert e.to_s.match(/is not under version control/)
      fails = true
    ensure
      FileUtils.rm file
    end
    assert fails
  end

  #def test_update
  # svn = SvnWc::RepoAccess.new(YAML::dump(@yconf), true)
  #for this one, we will have to create another working copy, modify a file
  # and commit from there, then to an update in this working copy
  #end

  #def test_update_a_locally_modified_file_raises_exception
  #for this one, we will have to create another working copy, modify a file
  # and commit from there, then to an update in this working copy
  #end

  #def test_delete
  #end

  #p = 'ba/htdocs/template'
  #f = 'click_line.tmpl'
  ##svn.commit_with_default_message(p, f)
  ##svn.update_file("#{p}/#{f}")
  #dir = '/Users/dwright/Documents/work/home/httpd'
  #f = svn.status(dir)
  #p f.inspect
  #puts f

  #
  # methods used by the tests below here
  #
 
  def new_unique_file_in_repo_root(wc_repo=@yconf['svn_repo_working_copy'])
    # XXX look into File.tmpfile (create a unique file each time) 
    new_file_name = File.join(wc_repo, "test_#{Time.now.usec.to_s}.txt")
    FileUtils.touch new_file_name
    #@wc_base_dir = File.join(Dir.tmpdir, "wc-tmp")
    #puts 'creating ' << new_file_name
    #p caller
    new_file_name
  end

  def _working_copy_repo_at_path(wc_repo=@wc_repo2)
    yconf = @yconf
    wc = yconf['svn_repo_working_copy']
    yconf['svn_repo_working_copy'] = wc_repo
    svn = SvnWc::RepoAccess.new(YAML::dump(yconf), true, true)
    yconf['svn_repo_working_copy'] = wc # reset to orig val
    svn
  end

  def delete_and_commit_files_from_another_working_copy_of_repo(files)
    svn = _working_copy_repo_at_path
    svn.delete files
    rev = svn.commit
    raise 'cant get rev' unless rev
    return rev
  end

  def check_out_new_working_copy_add_and_commit_new_entries(num_files=1)
    svn = _working_copy_repo_at_path
    ff = Array.new
    (1..num_files).each {|n|
      f = new_unique_file_in_repo_root(svn.svn_repo_working_copy)
      svn.add f
      ff.push f
    }
    rev = svn.commit ff
    #puts svn.status(f)[0][:status]
    #puts svn.info(f)[:rev]
    #raise 'cant get status' unless 'A' == svn.status(f)[0][:status]
    #raise 'cant get revision' unless rev == svn.info(f)[:rev]@
    raise 'cant get rev' unless rev
    return rev, ff
  end

  def modify_file_and_commit_into_another_working_repo(f)
    raise ArgumentError, "path arg is empty" unless f and not f.empty?
    svn = _working_copy_repo_at_path
    File.open(f, 'a') {|fl| fl.write('adding this to file.')}
    rev = svn.commit f
    raise 'cant get status' unless ' ' == svn.status(f)[0][:status]
    raise 'cant get revision' unless rev == svn.info(f)[:rev]
    rev
  end

end

