begin; require 'rubygems'; rescue LoadError; end
require 'test/unit'

# automated testing with celerity
#require 'celerity'

# ui testing with firewatir
require 'watir'
require 'firewatir'
include FireWatir

# XXX I cant figure out how to test this with celerity/watir

# TODO: ability to run in web browser

# TODO: look into
#http://stackoverflow.com/questions/2273524/firewatir-and-jquery
#@ie.js_eval("var target = getWindows()[0]; target.content.jQuery('#selector').toggle()")

# XXX geez, this is impossible.
# maybe just tests POSTS and responses
#do_svn_action	Do Svn Action
#svn_action	status
#svn_files


# unit tests to prove webapp functionality.
class TestSvnWcTree < Test::Unit::TestCase

  @@test_url = 'http://localhost/svn_wc_tree/index.html'
  # TODO add ability to set conf file via web UI
  #@@conf_file = 
  @@wc_repo_root = '/tmp/wordpress'

  @@file ='test_108251.txt'

  # XXX for now, make sure svn wc repo is rw for world, geez
  # both httpd owner and script run as user must access them

  # TODO be able to set up/install the web app for a test run
  # for now requires a installed webapp
  # create/modify some files in the path, (test diff)
  def setup
    #@ie = Celerity::Browser.new
    @ie = Watir::Browser.new
    @ie.goto @@test_url
  end

  def teardown
    @ie.close
  end

  def test_index_as_expected
    #browser.text_field(:name, 'q').value = 'Celerity'
    #browser.button(:name, 'btnG').click
    #puts "yay" if browser.text.include? 'celerity.rubyforge.org'
    assert @ie.text.include? "~\n[-]\n Loading ...\nProcessing..."
    #@ie.wait_until{@ie.text.include? 'Repository:'}
    Watir::Waiter.wait_until{@ie.text.include? 'Repository:'}
    assert @ie.text.include? 'Repository:'
    assert @ie.text.include? 'User:'
    assert @ie.text.include? 'Config File: /'
    #assert @ie.text.include? '[-]'
    #assert @ie.text.include? 'Repository is up to date.'
  end

  def test_svn_actions
    #@ie.wait_until{@ie.text.include? 'Repository:'}
    Watir::Waiter.wait_until{@ie.text.include? 'Repository:'}
    assert @ie.text.include? 'Repository:'

    # click checkbox for first entity (file)
    assert @ie.element_by_xpath("//li[@id='0']//a").click
    # works too
    ##assert @ie.element_by_xpath("//li[@id='0']/a/ins").click
    #assert_equal @ie.element_by_xpath("//li[@id='0']/a").text, @@file
    assert_equal File.basename(@ie.element_by_xpath("//li[@id='0']/a").text), @@file

    ## svn_status (is default)
    #assert @ie.element_by_xpath(:xpath, "//ul[@id='jstree-contextmenu']/li[2]/a/span").click
    #<td>//ul[@id='jstree-contextmenu']/li[6]/a/span</td>
    # svn_update
    #assert @ie.span(:xpath, "//ul[@id='jstree-contextmenu']/li[4]/a/span").click
    #assert @ie.element_by_xpath("//ul[@id='jstree-contextmenu']/li[4]/a/span").click
    puts @ie.element_by_xpath("//ul[@id='jstree-contextmenu']").text
    #puts @ie.element_by_xpath("//ul[@id='jstree-contextmenu']/li[4]/a/span").text

    puts @ie.element_by_xpath("//a[@class='svn_update ']/span").text
    puts @ie.element_by_xpath("//a[@class='svn_update ']/span").click

    puts @ie.span(:text, 'svn update')
    puts @ie.span(:text, 'svn update').click

    #puts @ie.link(:class, 'svn_update ').span.text
    puts @ie.link(:class, 'svn_update ').click
    #assert @ie.element_by_xpath("//ul[@id='jstree-contextmenu']/li[4]/a/span").click
    #puts @ie.element_by_xpath("//ul[@id='jstree-contextmenu']//li[4]//a//span").text
    #assert @ie.wait_until{@ie.text.include? 'Revision'}
    Watir::Waiter.wait_until{@ie.text.include? 'Revision'}
    assert @ie.text.include?  'Updated: Revision '

    abs_file_wc = File.join @@wc_repo_root, @@file
    assert @ie.text.include?  "M #{abs_file_wc}"
     

    #browser.element_by_xpath("//area[contains(@href , 'signup.htm')]").click()
       
    #<td>click</td>
    #<td>//ul[@id='jstree-contextmenu']/li[6]/a/span</td>
    #<td></td>
  end


end
