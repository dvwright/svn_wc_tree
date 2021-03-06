
require 'yaml'
require 'svn_wc'
require 'test/unit'
require 'fileutils'
require 'tempfile'
require 'time'
require 'json'
require 'cgi'
require File.join(File.dirname(__FILE__), "..", "lib", 'svn_wc_broker')

include SvnWcBroker

# unit tests to prove svn_wc_tree 
# just testing the 'REST' interface

class TestSvnWcTreeRestInterface < Test::Unit::TestCase

  @@do_svn_action = 'do_svn_action=' + CGI::escape('Do Svn Action')
  @@svn_action    = 'svn_action='
  @@svn_files     = 'svn_files='

  @@rest_post = "#{@@do_svn_action}&#{@@svn_action}&#{@@svn_files}"

  def setup
    @conf = {
      #"svn_repo_master"       => "svn+ssh://localhost/home/dwright/svnrepo",
      "svn_repo_master"        => "file://#{Dir.mktmpdir('R')}",
      #"svn_user"              => "svn_test_user",
      #"svn_pass"              => "svn_test_pass",
      "svn_repo_working_copy" => "#{Dir.mktmpdir('F')}",
      "svn_repo_config_path"  => Dir.mktmpdir('N')
    }
    write_conf_file
    sys_create_repo
    # force create working copy at repo root (created above)
    @svn_wc = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
  end

  def write_conf_file
    @conf_file = new_unique_file_at_path(Dir.mktmpdir('C'))
    File.open(@conf_file, 'w') {|fl| fl.write YAML::dump(@conf) }
    set_conf_file(@conf_file)
  end
  
  def sys_create_repo
    begin
      svnadmin =`which svnadmin`
      svn      =`which svn`
    rescue
      puts 'svn/svnadmin do not seem to be installed, Please install svn/svnadmin'
      exit 1
    end
    begin
      @svn_r_m = @conf['svn_repo_master'].gsub(/file:\/\//, '')
      # create repository for tests
      `"#{svnadmin.chomp}" create "#{@svn_r_m}"`
      # checkout a working copy of the repository just created for testing
      wc = @conf['svn_repo_working_copy']
      `cd "#{wc}" && "#{svn.chomp}" co "#{@conf['svn_repo_master']}"`
      @wc_repo2 = Dir.mktmpdir('E')
    rescue
      puts 'cannot create with the systems svn/svnadmin - all tests will Fail'
      exit 1
    end
  end

  def teardown
   # remove working copy of repo
   FileUtils.rm_rf @conf['svn_repo_working_copy']
   FileUtils.rm_rf @wc_repo2
   FileUtils.rm_rf @svn_r_m
   FileUtils.rm_rf @conf_file
  end

  def test_interface_default_top_level
    json_resp = JSON::parse self.post_to_rest
    #p json_resp
    json_resp.each do |ret_json|
      assert_equal @svn_wc.svn_repo_working_copy, ret_json['repo_root_local_path'].chop
      assert_equal @svn_wc.svn_repo_master,       ret_json['svn_repo_master']
      assert_equal @svn_wc.svn_user, ret_json['svn_user']
      assert_equal @conf_file,    ret_json['svn_repo_config_file']
      assert_equal Array,         ret_json['entries'].class
      assert_nil ret_json['status']
      assert_nil ret_json['file']
      assert_nil ret_json['content']
      assert_nil ret_json['error']
    end
  end

  def test_interface_default_entries
    json_resp = JSON::parse self.post_to_rest
    p json_resp
    entries = json_resp[0]['entries']
    entries.each do |ent|
      # XXX proves bug, a dir is being marked as a file!
      if ent['kind'] == 1
        assert File.file? ent['entry_name']
        #File.open(ent['entry_name'], 'r').readlines
        assert_equal '?', ent['status'] 
      end
      assert_equal 1, ent['kind'] unless ent['dir_name'] 
      assert_equal 2, ent['kind'] if ent['dir_name'] 
    end
  end

  # status is the default action, so this shoud be same as above
  def test_interface_svn_status
    @svn_action = @svn_action + 'status'
    #@svn_files + CGI::escape @files
    json_resp = JSON::parse self.post_to_rest
    entries = ret_json[0]['entries']
    entries.each do |ent|
      ent['entry_name'] 
      ent['status'] 
      assert_equal '1', ent['kind'] unless ent['dir_name'] 
      assert_equal '2', ent['kind'] if ent['dir_name'] 
    end
  end

  def svn_work_happens_add_file
    f = new_unique_file_at_path
    @svn_wc.add f
    #start_rev = svn.commit f
  end

  def test_add_commit_update_file_status_revision_modify_diff_revert
    #p svn.list_entries
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


  def test_add_commit_update_file_status_revision_modify_diff_revert
    f = new_unique_file_at_path
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


  #def test_exception_on_failed_authenticate
  #  conf = Hash.new
  #  conf['svn_user'] = 'fred'
  #  assert_raise SvnWc::RepoAccessError do
  #    #Svn::Error::AuthnNoProvider
  #     svn = SvnWc::RepoAccess.new(YAML::dump(conf), true)
  #  end
  #end

  #def test_exception_on_no_remote_repo
  #  conf = Hash.new
  #  conf['svn_repo_master'] = 'svn+ssh://user:pass@example.com/no/repo'
  #                               #"svn+ssh://username@hostname/path/to/repository
  #  assert_raise SvnWc::RepoAccessError do
  #    #Svn::Error::AuthnNoProvider
  #    SvnWc::RepoAccess.new(YAML::dump(conf), true)
  #  end
  #end

  def todo_test_exception_if_no_local_repo
    conf = Hash.new
    conf['svn_repo_working_copy'] = '/opt/nada'
    assert_raise SvnWc::RepoAccessError do
      # permission denied
      SvnWc::RepoAccess.new(YAML::dump(conf), true)
    end
  end

  #want to enable more?
  #info[:last_changed_author]
  #info[:changelist]
  #info[:url]
  #info[:rev]
  #info[:URL]
  #info[:root_url]
  #info[:uuid]
  #def test_can_get_svn_info
  #  svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
  #  #puts svn.info[:url]
  #  #puts svn.info[:rev]
  #  #puts svn.info[:URL]
  #  info = svn.info
  #  assert_equal info[:repos_root_url], @conf['svn_repo_master']
  #end

  def test_add_non_existant_file_fails
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = 'thisfiledoesnotexist.txt'
    begin
      svn.add file
      fail 'cant add a file which does not exist'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not a working copy/)
      assert e.to_s.match(/Add Failed/)
    end
  end

  def test_commit_non_existant_file_fails
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = 'thisfiledoesnotexist.txt'
    begin
      svn.commit file
      fail 'cant commit file which does not exist'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not a working copy/)
    end
  end

  def test_add_non_readable_file_fails
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = new_unique_file_at_path
    FileUtils.chmod 0000, file
    begin
      svn.add file
      fail 'lacking permissions to view file'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/Permission denied/)
    ensure
      FileUtils.rm file
    end
  end

  def test_try_get_info_on_file_not_under_version_control
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = new_unique_file_at_path
    begin
      info = svn.info(file)
      orig_rev = info[:rev]
      fail 'is not under version control'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not under version control/)
    ensure
      FileUtils.rm file
    end
  end

  def test_add_new_dir_and_file_and_commit_and_delete
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = new_unique_file_at_path
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

  def test_add_new_dir_and_file_and_commit_and_delete_with_pre_open_instance
    @@svn_wc.set_conf @conf_file
    @@svn_wc.do_checkout true
    file = new_unique_file_at_path
    begin
      @@svn_wc.info(file)
      fail 'file not in svn'
    rescue SvnWc::RepoAccessError => e
      assert e.message.match(/is not under version control/)
    end
    @@svn_wc.add file
    rev = @@svn_wc.commit file
    assert rev >= 1
    @@svn_wc.delete file
    # commit our delete
    n_rev = @@svn_wc.commit file
    assert_equal rev+1, n_rev
  end

  def test_add_and_commit_several_select_new_dirs_and_files_then_svn_delete
    svn = SvnWc::RepoAccess.new(@conf_file, true, true)

    f = []
    (1..4).each { |d|
      wc_new_dir = File.join @conf['svn_repo_working_copy'], "dir#{d}"
      FileUtils.mkdir wc_new_dir
      wc_new_file = "test_#{d}.txt"
      f[d] = File.join wc_new_dir, wc_new_file
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
    assert File.file?(f[3])
    assert FileUtils.rm_rf(File.dirname(f[3]))
  end

  def test_add_commit_update_file_status_revision_modify_diff_revert
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    f = new_unique_file_at_path
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
  #  FileUtils.mkdir_p @conf['svn_repo_working_copy'] + "/d1/d2/d3"
  #  nested = @conf['svn_repo_working_copy'] +
  #                    "/d1/d2/d3/test_#{Time.now.usec.to_s}.txt"
  #  FileUtils.touch nested
  #  svn.add nested

  #  svn.status.each { |ef|
  #    next unless ef[:entry_name].match /test_.*/
  #    assert_equal 'A', ef[:status]
  #    assert_equal nested, File.join(@conf['svn_repo_working_copy'], ef[:entry_name])
  #  }
  #  svn.revert
  #  assert_equal 1, svn.status.length
  #  assert_equal File.basename(@conf['svn_repo_working_copy']),
  #                     svn.status[0][:entry_name]
  #end

  def test_update_acts_on_whole_repo_by_default_knows_a_m_d
    #conf = Hash.new
    #conf['svn_repo_master']       = 'file:///tmp/svnrepo'
    #conf['svn_repo_working_copy'] = '/tmp/testing'
    #svn = SvnWc::RepoAccess.new(YAML::dump(conf))
    #p svn.list_entries
    #exit
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)

    rev = svn.info()[:rev]
    assert_equal [rev, []], svn.update

    (rev1, files)  = check_out_new_working_copy_add_and_commit_new_entries(3)
    assert_equal rev+1, rev1

    fe = Array.new
    files.each { |e| fe.push File.basename(e)}
    assert_equal \
      [(rev + 1), ["A\t#{fe[0]}", "A\t#{fe[1]}", "A\t#{fe[2]}"]],
      svn.update, 'added 3 files into another working copy of the repo, update
                   on current repo finds them, good!'

    # Confirm can do add/delete/modified simultaniously
    # modify, 1 committed file, current repo
    lf = File.join @conf['svn_repo_working_copy'], fe[0]
    File.open(lf, 'a') {|fl| fl.write('local repo file is modified')}
    # delete, 2 committed file, in another repo
    rev2 \
       = delete_and_commit_files_from_another_working_copy_of_repo(
                                                       [files[1], files[2]]
                                                                  )
    # add 1 file, in another repo
    (rev3, file)  = check_out_new_working_copy_add_and_commit_new_entries
    fe.push File.basename(file[0])

    assert_equal \
      [(rev + 3), ["M\t#{fe[0]}", "A\t#{fe[3]}", "D\t#{fe[1]}", "D\t#{fe[2]}"]],
      svn.update, '1 modified locally, 2 deleted in other repo, 1 added other
      repo, update locally, should find all these changes'

  end

  #def test_update_reports_collision
  #  svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)

  #  assert_equal '', svn.update

  #  rev, f_name = check_out_new_working_copy_add_and_commit_new_entries

  #  assert_equal " #{f_name}", svn.update

  #  f = new_unique_file_at_path
  #  modify_file_and_commit_into_another_working_repo(f)
  #  File.open(f, 'a') {|fl| fl.write('adding text to file.')}
  #  # XXX no update done, so this file should clash with
  #  # what is already in the repo
  #  start_rev = svn.commit f
  #  #p svn.status(f)
  #  #assert_equal 'M', svn.status(f)[0][:status]
  #  #assert_equal start_rev, svn.info(f)[:rev] 
  #end

  def test_list_recursive
    FileUtils.rm_rf @conf['svn_repo_working_copy']

    if ! File.directory?(@conf['svn_repo_working_copy'])
      FileUtils.mkdir @conf['svn_repo_working_copy'] 
    end

    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)

    # how many files does svn status find?
    r_list = []
    svn.list.each { |ef|
      r_list.push File.join(@conf['svn_repo_working_copy'], ef[:entry])
    }

    # not cross platform
    dt = Dir["#{@conf['svn_repo_working_copy']}/**/*"]
    d_list = []
    dt.each do |item|
      #case File.stat(item).ftype
      d_list.push item
    end

    the_diff = r_list - d_list
    # not cross platform
    assert_equal the_diff, [File.join(@conf['svn_repo_working_copy'], '/')]
    #puts the_diff
    #p d_list.length
    #p r_list.length
    assert_equal d_list.length, r_list.length-1

  end

  def test_status_n_revert_default_to_repo_root
    FileUtils.rm_rf @conf['svn_repo_working_copy']

    if ! File.directory?(@conf['svn_repo_working_copy'])
      FileUtils.mkdir @conf['svn_repo_working_copy']
    end

    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)

    #puts svn.status
    repo_wc = @conf['svn_repo_working_copy']

    # add 4 new files in the repo root
    num_create = 4
    add_files = []
    (1..num_create).each { |d|
      fl = new_unique_file_at_path
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

  def test_commit_file_not_yet_added_to_svn_raises_exception
    svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true, true)
    file = new_unique_file_at_path
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
  # svn = SvnWc::RepoAccess.new(YAML::dump(@conf), true)
  #for this one, we will have to create another working copy, modify a file
  # and commit from there, then to an update in this working copy
  #end

  #def test_update_a_locally_modified_file_raises_exception
  #for this one, we will have to create another working copy, modify a file
  # and commit from there, then to an update in this working copy
  #end

  #def test_delete
  #end

  #
  # methods used by the tests below here
  #

  def post_to_rest
   handle_responses(@@rest_post).to_json
  end
 
  def new_unique_file_at_path(wc_repo=@conf['svn_repo_working_copy'])
    #Tempfile.new('test_', wc_repo).path
    new_file_name = File.join(wc_repo, "test_#{Time.now.usec.to_s}.txt")
    FileUtils.touch new_file_name
    new_file_name
  end

  def _working_copy_repo_at_path(wc_repo=@wc_repo2)
    conf = @conf
    wc = conf['svn_repo_working_copy']
    conf['svn_repo_working_copy'] = wc_repo
    svn = SvnWc::RepoAccess.new(YAML::dump(conf), true, true)
    conf['svn_repo_working_copy'] = wc # reset to orig val
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
      f = new_unique_file_at_path(svn.svn_repo_working_copy)
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

if VERSION < '1.8.7'
  # File lib/tmpdir.rb, line 99
  def Dir.mktmpdir(prefix_suffix=nil, tmpdir=nil)
    case prefix_suffix
    when nil
      prefix = "d"
      suffix = ""
    when String
      prefix = prefix_suffix
      suffix = ""
    when Array
      prefix = prefix_suffix[0]
      suffix = prefix_suffix[1]
    else
      raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
    end
    tmpdir ||= Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      path << suffix
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path
      end
    else
      path
    end
  end
end

