Gem::Specification.new do |s|
  s.name        = %q{svn_wc_tree}
  s.version     = "0.0.7"
  s.date        = %q{2011-08-19}
  s.authors     = ["David Wright"]
  s.email       = %q{david_v_wright@yahoo.com}
  s.summary     = %q{svn_wc_tree is a web application (GUI) that enables 
                     basic operations on a working copy of a Subversion repository.}
  s.homepage    = %q{http://www.dwright.us/misc/svn_wc_tree}
  s.description = %q{svn_wc_tree provides an Web Application Front End GUI
                     to a working copy of an remote SVN Repository.}
  s.executables = %q{svn_wc_tree}
  s.files       = %w(
                     bin/svn_wc_tree
                     cgi/svn_wc_broker.cgi
                     ChangeLog
                     lib/svn_wc_broker.rb
                     lib/svn_wc_client.rb
                     tests/test_installer_bin.rb
                     Manifest
                     README.rdoc
                     svn_conf.yaml
                     svn_wc_tree/css/swt.css
                     svn_wc_tree/img/swt_spinner.gif
                     svn_wc_tree/index.html
                     svn_wc_tree/index.php
                     svn_wc_tree/js/swt.js
                     svn_wc_tree/js/jquery-1.3.2.js
                     svn_wc_tree/js/jquery.blockUI-2.31.js
                     svn_wc_tree/js/jquery.cookie.js
                     svn_wc_tree/js/jquery.tree.checkbox.js
                     svn_wc_tree/js/jquery.tree.js
                     svn_wc_tree/js/source/jquery.tree.js
                     svn_wc_tree/js/source/jquery.tree.min.js
                     svn_wc_tree/js/source/lib/jquery.cookie.js
                     svn_wc_tree/js/source/lib/jquery.hotkeys.js
                     svn_wc_tree/js/source/lib/jquery.js
                     svn_wc_tree/js/source/lib/jquery.metadata.js
                     svn_wc_tree/js/source/lib/sarissa.js
                     svn_wc_tree/js/source/plugins/_jquery.tree.rtl.js
                     svn_wc_tree/js/source/plugins/jquery.tree.checkbox.js
                     svn_wc_tree/js/source/plugins/jquery.tree.contextmenu.js
                     svn_wc_tree/js/source/plugins/jquery.tree.cookie.js
                     svn_wc_tree/js/source/plugins/jquery.tree.hotkeys.js
                     svn_wc_tree/js/source/plugins/jquery.tree.metadata.js
                     svn_wc_tree/js/source/plugins/jquery.tree.themeroller.js
                     svn_wc_tree/js/source/plugins/jquery.tree.xml_flat.js
                     svn_wc_tree/js/source/plugins/jquery.tree.xml_nested.js
                     svn_wc_tree/js/source/themes/apple/bg.jpg
                     svn_wc_tree/js/source/themes/apple/dot_for_ie.gif
                     svn_wc_tree/js/source/themes/apple/icons.png
                     svn_wc_tree/js/source/themes/apple/style.css
                     svn_wc_tree/js/source/themes/apple/throbber.gif
                     svn_wc_tree/js/source/themes/checkbox/dot_for_ie.gif
                     svn_wc_tree/js/source/themes/checkbox/icons.png
                     svn_wc_tree/js/source/themes/checkbox/style.css
                     svn_wc_tree/js/source/themes/checkbox/throbber.gif
                     svn_wc_tree/js/source/themes/classic/dot_for_ie.gif
                     svn_wc_tree/js/source/themes/classic/icons.png
                     svn_wc_tree/js/source/themes/classic/style.css
                     svn_wc_tree/js/source/themes/classic/throbber.gif
                     svn_wc_tree/js/source/themes/default/dot_for_ie.gif
                     svn_wc_tree/js/source/themes/default/icons.png
                     svn_wc_tree/js/source/themes/default/style.css
                     svn_wc_tree/js/source/themes/default/throbber.gif
                     svn_wc_tree/js/source/themes/themeroller/dot_for_ie.gif
                     svn_wc_tree/js/source/themes/themeroller/icons.png
                     svn_wc_tree/js/source/themes/themeroller/style.css
                     svn_wc_tree/js/source/themes/themeroller/throbber.gif
                     )
end

