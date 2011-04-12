require 'test/unit'
require 'fileutils'
require 'tempfile'

# unit tests to prove installation of svn_wc_tree
# just testing the bin/ installer

class TestSvnWcTreeBinInstaller < Test::Unit::TestCase

  INSTALLER = File.join(File.dirname(__FILE__), "..", "bin", 'svn_wc_tree')

# --html, -l [html_dir]:
#    Move all web files to the directory path specified. 
#    A directory called svn_wc_tree will be created at this path.
#
# --cgi, -c [cgi_dir]:
#    Move the included CGI script to the path specified.
#    path/directory must exist and must be able to execute CGI scripts
#
# --post_to_url, -u [post_to_url]:
#    a URL that will receive AJAX requests and return the required JSON.
#    (see the CGI script provided)
#
# --php, -p [php]:
#    Run as a PHP application. (use only as last choice)
#    (Ruby is still required; CGI not needed)
#
# --conf_location, -u [conf_location]:
#    location (filesystem path) of your svn_wc.conf file (readable by 'httpd
#    runs as' owner)
#
# --copy_conf_from, -f [copy_conf_from]:
#    move your conf file (svn_conf.yaml) from filesystem path to 
#    (copy_conf_to)
#
# --copy_conf_to, -t [copy_conf_to]:
#    move your conf file (svn_conf.yaml) to filesystem path from
#    (copy_conf_from)
#
#
# Example: 
#   svn_wc_tree --html /var/htdocs --cgi /var/cgi-bin \ 
#                   --post_to_url 'http://example.com/cgi-bin/' \
#                   --conf_location /opt/conf/svn_conf.yaml
#
#   sudo svn_wc_tree --html /var/htdocs --php true \
#                    --conf_location /opt/svn_wc_tree/svn_conf.yaml
#
#   sudo svn_wc_tree --html /var/www --cgi /usr/lib/cgi-bin \
#    --post_to_url 'http://localhost/cgi-bin/' --copy_conf_from \
#    /tmp/svn_conf.yaml --copy_conf_to /usr/local/svn_wc_tree

  def setup
    @conf = {
      #"svn_repo_master"       => "svn+ssh://localhost/home/dwright/svnrepo",
      "svn_repo_master"        => "file://#{Dir.mktmpdir('R')}",
      #"svn_user"              => "svn_test_user",
      #"svn_pass"              => "svn_test_pass",
      "svn_repo_working_copy" => "#{Dir.mktmpdir('F')}",
      "svn_repo_config_path"  => Dir.mktmpdir('N')
    }
    #@conf_file = new_unique_file_at_path(Dir.mktmpdir('C'))
    @conf_file = Tempfile.new(%w(conf_ .yaml)).path
    File.open(@conf_file, 'w') {|fl| fl.write YAML::dump(@conf) }
  end
 
  def teardown
    FileUtils.rm_r @html_dir if @html_dir
    FileUtils.rm_r @cgi_dir  if @cgi_dir
    #FileUtils.rm_r @conf_file
  end

  def test_no_arg
    assert `#{INSTALLER}`.match('Required argument missing')
  end

  def test_help
    opt = '--help'
    #assert `#{INSTALLER} #{opt}`.grep(/Usage\n-----\nsvn_wc_tree \[OPTIONS\]/)[0]
    assert `#{INSTALLER} #{opt}`.match('svn_wc_tree: install the svn_wc_tree web application.')
    opt = '-h'
    assert `#{INSTALLER} #{opt}`.match('svn_wc_tree: install the svn_wc_tree web application.')
  end

  def test_missing_required_arg
    opt = '--php true'
    assert `#{INSTALLER} #{opt}`.match('Required argument missing')
  end

  def test_required_arg_empty
    opt = '--html ""'
    assert `#{INSTALLER} #{opt}`.match('path cannot be empty!')
  end

  def test_most_basic_install_non_functional__no_php_no_cgi_no_conf
    @html_dir = Dir.mktmpdir('H')

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opt = "--html #{@html_dir}"
    # no output, is success
    assert `#{INSTALLER} #{opt}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js'))
  end

  def test_basic_install_functional__no_php_no_cgi_no_conf_POST_to_other_resource
    @html_dir = Dir.mktmpdir('H')

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opts = "--html #{@html_dir} --post_to_url '/svn/svn_controller'"

    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    js_file =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    assert File.file? js_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = '\/svn\/svn_controller';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
  end

  # works but doesn't make sense,...
  # conf file must be added by hand to the POST resource

  # why would you want this combination?
  def test_conf_path_not_written_anywhere__install_no_php_no_cgi
    @html_dir = Dir.mktmpdir('H')

    assert File.file?(@conf_file)
    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opts = "--html #{@html_dir} --post_to_url '/svn/svn_controller' "
    opts << "--conf_location #{@conf_file}"

    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    js_file =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    assert File.file? js_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = '\/svn\/svn_controller';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
  end

  def test_default_js_file_POST_url_is_empty
    js_file = File.join(File.dirname(__FILE__), "..", 
                                      'svn_wc_tree', 'js', 'swt.js')
    assert File.file? js_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = '';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
  end

  def test_default_cgi_file_POST_url_is_empty
    cgi_file =  File.join('..', 'cgi', 'svn_wc_broker.cgi')
    cgi_file = File.join(File.dirname(__FILE__), "..", 'cgi', 
                                                 'svn_wc_broker.cgi')
    assert File.file? cgi_file

    is_ok = false
    is_ok2 = false
    File.readlines(cgi_file).each do |line| 
      if line.grep(/CONF_FILE = nil/)[0]
        is_ok = true
        next
      end

      if line.grep(/print cgi.header/)[0] 
        is_ok2 = true 
        break 
      end

    end
    assert is_ok
    assert is_ok2
  end

  # conf file must be added by hand to the POST resource (wherever that is)
  def test_install_functional__php_no_conf
    @html_dir = Dir.mktmpdir('H')

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opts = "--html #{@html_dir} --php true"

    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.php'))
    js_file =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    assert File.file? js_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = 'index.php';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
  end

  def test_install_functional__php_w_conf
    @html_dir = Dir.mktmpdir('H')

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opts = "--html #{@html_dir} --php true "
    opts << "--conf_location #{@conf_file}"

    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.php'))
    js_file  =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    cgi_file =  File.join(@html_dir, 'svn_wc_tree', 'svn_wc_broker.cgi')
    assert File.file? js_file
    assert File.file? cgi_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = 'index.php';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok

    is_ok  = false
    is_ok2 = false
    File.readlines(cgi_file).each do |line| 
      if line.grep(/CONF_FILE = '#{@conf_file}'/)[0]
        is_ok = true
        next
      end
      if line.grep(/#print cgi.header/)[0]
        is_ok2 = true
        break
      end
    end
    assert is_ok
    assert is_ok2
  end

  def test_install_functional__cgi_w_conf
    @html_dir = Dir.mktmpdir('H')
    @cgi_dir  = Dir.mktmpdir('C')

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))

    opts = "--html #{@html_dir} --cgi #{@cgi_dir} --conf_location #{@conf_file} "
    opts << "--post_to_url 'http://example.com/cgi-bin/'"

    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    # is still copied over, do we want that, if not needed?
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.php'))
    # not php mode, so not copied to html/php dir
    assert !File.file?(File.join(@html_dir, 'svn_wc_tree', 'svn_wc_broker.cgi'))

    js_file  =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    cgi_file =  File.join(@cgi_dir, 'svn_wc_broker.cgi')
    assert File.file? js_file
    assert File.file? cgi_file

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = 'http:\/\/example.com\/cgi-bin\/';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok

    is_ok = false
    File.readlines(cgi_file).each do |line| 
      if line.grep(/CONF_FILE = '#{@conf_file}'/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
  end

  # TODO
  #def test_cgi_precendence_over_php_if_both_set
  # try mis-matched opts

  def test_install_functional_cgi_all_opts
    @html_dir = Dir.mktmpdir('H')
    @cgi_dir  = Dir.mktmpdir('C')
    @conf_to  = Dir.mktmpdir('F')

    @new_conf = File.join(@conf_to, File.basename(@conf_file))

    assert !File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(@conf_file)
    assert !File.file?(@new_conf)

    opts = "--html #{@html_dir} --cgi #{@cgi_dir} "
    opts << "--post_to_url 'http://example.com/cgi-bin/' "
    opts << "--copy_conf_from #{@conf_file} "
    opts << "--copy_conf_to #{@conf_to} "
    opts << "--conf_location #{@new_conf} "
 
    # no output, is success
    assert `#{INSTALLER} #{opts}`.empty?

    # created dir at target location
    assert File.directory?(File.join(@html_dir, 'svn_wc_tree'))
    assert File.file?(File.join(@html_dir, 'svn_wc_tree', 'index.html'))
    assert File.directory?(@conf_to)

    js_file  =  File.join(@html_dir, 'svn_wc_tree', 'js', 'swt.js')
    cgi_file =  File.join(@cgi_dir, 'svn_wc_broker.cgi')
    assert File.file? js_file
    assert File.file? cgi_file

    assert File.file?(@conf_file)
    assert File.file?(@new_conf)

    is_ok = false
    File.readlines(js_file).each do |line| 
      if line.grep(/var POST_URL = 'http:\/\/example.com\/cgi-bin\/';/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok

    is_ok = false
    File.readlines(cgi_file).each do |line| 
      if line.grep(/CONF_FILE = '#{@new_conf}'/)[0]
        is_ok = true
        break
      end

      if line.grep(/print cgi.header/)[0]
        is_ok = true
        break
      end
    end
    assert is_ok
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
        FileUtils.rm_r path
      end
    else
      path
    end
  end
end

