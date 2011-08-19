// Copyright (c) 2009 David Wright
//
// You are free to modify and use this file under the terms of the GNU LGPL.
// You should have received a copy of the LGPL along with this file.
//
// Alternatively, you can find the latest version of the LGPL here:
//
//      http://www.gnu.org/licenses/lgpl.txt
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.

// change for your host if necessary
var POST_URL = '';

///////////////////////////////////////////////////////////////////////////////
// dont change anything below here                                           //
///////////////////////////////////////////////////////////////////////////////

//XXX/TODO this file needs to be refactored
// TODO upgrade to 1.0.a, or whatever newest of jstree is, unfortunelty
//      the API does not appear to be backwards compatible, so a rewrite will be
//      needed

var STATUS_SPACER = "\t"; // "&nbsp;"
var SVN_ACTION = '';

// jQuery BlockUI Plugin (v2)
$.blockUI.defaults.message = '<img src="img/swt_spinner.gif" /> Processing... ';
$.blockUI.defaults.css = 
              {
                padding:        0,
                margin:         0,
                width:          '40%',
                top:            '40%',
                left:           '35%',
                textAlign:      'center',
                color:          '#000',
                //border:         '3px solid #aaa',
                backgroundColor:'#fff',
                cursor:         'wait'
              };

// use yellow overlay 
//$.blockUI.defaults.overlayCSS.backgroundColor = '#ccc';
// make overlay more transparent
//$.blockUI.defaults.overlayCSS.opacity = 12;
//$.blockUI.defaults.applyPlatformOpacityRules = false;
$(document).ajaxStart($.blockUI).ajaxStop($.unblockUI);

$(document).ready(function(){
  var CHECKED_FILE_NAMES = []
  var SVN_ENTRIES = []

  // 'onload' populate 'keep filter' if has been set
  keep_filter('swt_filter_re', $.cookie('swt_filter_re'));
  keep_filter('swt_dir', $.cookie('swt_dir'));

  // the repo tree
  $(function () {
    $("#svn_repo_entries_tree").tree({
      plugins : {
        contextmenu : {
          items : {
            // get rid of the default js_tree actions
            remove : false,
            rename : false,
            create : false,
            //my_act : {
            //  label     : "My own action",
            //  icon      : "", // you can set this to a classname or a path to an icon like ./myimage.gif
            //  visible   : function (NODE, TREE_OBJ) {
            //    // this action will be disabled if more than one node is selected
            //    if(NODE.length != 1) return 0;
            //    // this action will not be in the list if condition is met
            //    if(TREE_OBJ.get_text(NODE) == "Child node 1") return -1;
            //    // otherwise - OK
            //    return 1;
            //  },
            //  action    : function (NODE, TREE_OBJ) {
            //    alert(TREE_OBJ.get(NODE, "xml_nested", false));
            //  },
            //  separator_before : true
            //},
            // status occurs every time anyway
            // svn status menu option
            svn_status : {
              label     : 'svn status',
              icon      : '',
              action    : function (NODE, TREE_OBJ) { 
                            SVN_ACTION = 'status';
                            TREE_OBJ.callback('beforedata', [NODE, TREE_OBJ]);
                            $.tree.focused().refresh();//refresh does a http POST
                          },
              separator_before : true
            },
            // svn update menu option
            svn_update : {
              label     : "svn update",
              action    : function (NODE, TREE_OBJ) {
                            post_req_svn_resp('update');
                          },
              separator_before : true
            },
            // svn diff menu option
            svn_diff : {
              label     : 'svn diff',
              icon      : '',
              action    : function (NODE, TREE_OBJ) {post_req_svn_resp('diff');},
              separator_before : true
            },
            // svn commit menu option
            svn_commit : {
              label     : 'svn commit',
              icon      : '',
              action    : function (NODE, TREE_OBJ) { 
                            var enode = TREE_OBJ.get_text(NODE);
                            //console.log('['+enode+']');
                            //if (enode.match(/\S+\s+.*?/))
                              post_req_svn_resp('commit');
                            //else alert(enode + ' is upto date');
                           },
              separator_before : true
            },
            // svn info menu option
            svn_info : {
              label     : 'svn info',
              icon      : '',
              action    : function (NODE, TREE_OBJ) {
                            post_req_svn_resp('info');
                          },
              separator_before : true
            },
            // svn add menu option
            svn_add : {
              label     : 'svn add',
              icon      : '',
              action    : function (NODE, TREE_OBJ) {
                            post_req_svn_resp('add');
                          },
              separator_before : true
            },
            // svn delete menu option
            svn_delete : {
              label     : 'svn delete',
              icon      : '',
              action    : function (NODE, TREE_OBJ) { post_req_svn_resp('delete'); },
              separator_before : true
            },
            // svn list all repo entries
            svn_list : {
              label     : 'svn list',
              icon      : '',
              //action    : function (NODE, TREE_OBJ) { post_req_svn_resp('list'); },
              action    : function (NODE, TREE_OBJ) {
                SVN_ACTION = 'list';
                TREE_OBJ.callback('beforedata', [NODE, TREE_OBJ]);
                //XXX THIS IS IT, refresh does a POST!
                $.tree.focused().refresh();
              },
              separator_before : true
            },
            // svn delete menu option
            svn_revert : {
              label     : 'svn revert',
              icon      : '',
              action    : function (NODE, TREE_OBJ) { post_req_svn_resp('revert'); },
              separator_before : true
            },
            // svn ignore files
            // XXX todo - for now make a igrnoe list
            // and run svn propset svn:ignore -F ignore.txt . in repo root
            //svn_ignore : {
            //  label     : 'svn ignore',
            //  icon      : '',
            //  action    : function (NODE, TREE_OBJ) {
            //                post_req_svn_resp('ignore');
            //              },
            //  separator_before : true
            //},
            refresh : {
              label     : "refresh tree",
              action    : function (NODE, TREE_OBJ) {
                var re_filter = $("#swt_filter_re").val();
                var dir = $("#swt_dir").val();
                //console.log(re_filter);
                // set current filter to a cookie 
                $.cookie('swt_filter_re', re_filter);
                $.cookie('swt_dir', dir);
                window.location.reload();
                //history.go();
              },
              separator_before : true
            }
            //remove : {
            //  label     : "Filesystem Delete",
            //  icon      : "remove",
            //  visible   : function (NODE, TREE_OBJ) {
            //    var ok = true;
            //    $.each(NODE, function () {
            //      if(TREE_OBJ.check("deletable", this) == false) {
            //        ok = false;
            //        return false;
            //      }
            //    });
            //    return ok;
            //  },
            //  action    : function (NODE, TREE_OBJ) {
            //    $.each(NODE, function () {
            //      var enode = TREE_OBJ.get_text(NODE);
            //      if(confirm('Delete ' + enode + '?')) {
            //        post_req_non_svn('delete');
            //        TREE_OBJ.remove(this);
            //      }
            //    });
            //  }
            //}
          }
        },
        checkbox : { //three_state: false
        }
      },
      //ui : { theme_name : "classic" },
      ui : { theme_name : "checkbox"
             //theme_path : "/js/svn_wc_tree/source/themes/checkbox/style.css" 
      },
      data : {
        title : "Svn Repository Tree",
        type : "json",
        //async : true,
        opts : {
            method : "POST",
            url  : POST_URL
        }
      },
      callback : {
        onselect : function (NODE, TREE_OBJ) {
          //console.log($(NODE).attr('id'));
          CHECKED_FILE_NAMES[$(NODE).attr('id')] = TREE_OBJ.get_text(NODE);
        },
        //Triggered when a node is rightclicked
        onrgtclk : function(NODE, TREE_OBJ, EV) {
         // disable browser action on right click
         EV.preventDefault();
         EV.stopPropagation();
         return false;
        },
        ondata : function(DATA, TREE_OBJ) { 
          return on_data(DATA, TREE_OBJ);
        },
        beforedata : function(NODE, TREE_OBJ) {
          //console.log('beforedata' + $(NODE).attr('id'));
          return {
            'do_svn_action': 'Do Svn Action',
            'svn_action'   : SVN_ACTION,
            'svn_files'    : [gather_selected_files()],
            'dir'          : $("#swt_dir").val(),
            'filter_re'    : $("#swt_filter_re").val(),
            'filter_amt'   : $("#swt_filter_amt").val()
          }
        }
      }
    });
  });

  // XXX this is called for all ajax requests (i.e. 'refresh')
  function on_data(DATA, TREE_OBJ) {
    //console.log('on DATA'); console.log(DATA);
    if (!DATA) document.write('No Data received, possibly your session expired');

    var entries_list = new Array

    if (DATA && DATA.length) {
      $("#svn_local_repo_root").val(DATA[0].repo_root_local_path);
      
      // display high level repo info
      display_repo_info(DATA[0]);

      if (DATA[0].run_error) return display_error_message(DATA[0].run_error);
      if (DATA[0].error) return display_error_message(DATA[0].error);
      if (DATA[0].entries == undefined) display_error_message('no result');

      var amount_of_entries = DATA[0].entries.length;
      if (amount_of_entries == 0) {
        if ($("#swt_filter_re").val()) report_no_match_if_filter();
        if ($("#swt_dir").val()) report_no_match_if_filter();
        else repo_up_to_date();

        // use repo root as default when no results
        var repo_default = {
          'state' : 'open',
          'data'  :  DATA[0].repo_root_local_path
        }
        entries_list.push(repo_default);
      }
      for (i = 0; i<amount_of_entries; i++) {
        ent = DATA[0].entries[i];
        if (ent === undefined) continue;
        //console.log(ent);
        entries_list.push(ent);
      }
    }
    //console.log(entries_list);
    return entries_list;
  }

  function keep_filter(name, re_filter){
    //console.log(re_filter);
    //$("#swt_filter_re").val(re_filter);
    $('#'+name).val(re_filter);
  }

  // limit result set with filter
  function is_filtered(file_name, re_filter){
    if(!file_name.match(re_filter)) return true;
    return false;
  }

  function report_no_match_if_filter(){
    $("#svn_action_results").prepend('<p style="color:blue">No Match.</p>');
  }

  function repo_up_to_date(){
    $("#svn_action_results").prepend('<p style="color:blue">'
                                     + 'Repository is up to date.</p>');
  }

  function post_req_non_svn(action) {
    //console.log('non svn request' + action);
    $(function() {
      $.post(
         POST_URL, // post to url
         {
           'do_action' : action,
           'files'     : [gather_selected_files()]
         },
         // server response
         function(resp){
           //console.log(resp);
           // is a runtime error
           if (resp && resp[0] && resp[0].run_error) {
             display_error_message(resp[0].run_error);
           }
         },
         'json'
      );
    });
  };

  function post_req_svn_resp(svn_action) {
    //console.log('post_req_svn_resp');
    $(function() {
      $.post(// post to url
         POST_URL, {
           'do_svn_action': 'Do Svn Action',
           'svn_action'   : svn_action,
           'svn_files'    : [gather_selected_files()]
         },
         // server response for svn action
         function(resp){
           process_server_response(svn_action,resp);
         },
         'json'
      );
    });
    return SVN_ENTRIES; // is global, not really necessary to return
  };

  function gather_selected_files(){
    var svn_files = new Array;
    ($.tree.plugins.checkbox.get_checked(
      $.tree.reference("#svn_repo_entries_tree"))).each(
       function () {
         if(CHECKED_FILE_NAMES[this.id] !== undefined){
           // absolute filesystem path location
           entry = CHECKED_FILE_NAMES[this.id];
           //#&nbsp; becomes odd 2 byte char
           //entry.replace(/((\302\240)+|\t+|\s+)/, " ");
           entry = entry.replace(/\s+/, ' ');
           var info = entry.split(' ', 2);
           //var abs_pn = info[0] + ' ' + $("#svn_local_repo_root").val() + info[1]
           //console.log('in checked files');
           //console.log(info);

           var abs_pn = info[0] + ' ' + info[1]

           // XXX this is a hck fix, figure it out
           // odd bug, svn_files /home/httpd undefined
           // just repo root sent, other files not seen!?
           if (info[1] === undefined) abs_pn = info[1] + ' ' + info[0]

           svn_files.push(abs_pn);
         }
         //console.log(svn_files);
       }
     )
     return svn_files;
  }

  function process_server_response(svn_action, resp){
    //console.log(resp + svn_action);

    // is a runtime error
    // XXX clean up server response - make consistent
    var run_err = undefined;
    if (resp && resp[0] && resp[0].run_error) run_err = resp[0].run_error;
    else if (resp && resp.run_error) run_err = resp.run_error;

    if (run_err) return display_error_message(resp.run_error);

    // update tree display post success action
    if (svn_action == 'commit') change_display_selected_files(STATUS_SPACER);
    if (svn_action == 'revert') change_display_selected_files(STATUS_SPACER);
    //if (svn_action == 'add')    change_display_selected_files('A');

    var show_response_area = false;
    var display_svn_results = '';

    for(i=0;i<resp.length;i++) {
      if (resp[i].error || resp[i].content) show_response_area = true;

      display_svn_results = process_content_and_entries(resp[i], svn_action,
                                                           display_svn_results);
      //console.log(display_svn_results);
    }

    if (show_response_area) $('#show_hide_container').show();
    // populate our div
    $("#svn_action_results").html(display_svn_results);
  }
  
  function process_content_and_entries(jdata, svn_action, display_svn_results){
     var error = '';
     var contents = '';

     if (jdata.error) error = '<p style="color:red">'+jdata.error+'</p>';

     // used for 'diff'
     if (jdata.content) // expand newline to line break, '<' to html entity
       contents += jdata.content.replace(/</g, '&lt;').replace(/\n/g, '<br/>');

     //if (jdata.entries) process_entries(jdata.entries, svn_action);

     if (jdata.repo_root_local_path)
       $("#svn_local_repo_root").val(jdata.repo_root_local_path);

     if (contents)
       display_svn_results += error + '<p style="color:grey">'+contents+'</p>';
     else
       display_svn_results += error;

     return display_svn_results;
  }

  function process_entries(entries, svn_action){
    SVN_ENTRIES = entries;
    if (svn_action == 'status'){
      //console.log('in status');
      //for(j=0;j<SVN_ENTRIES.length;j++){
      //  //$.tree.focused().remove('#' + j);
      //  // XXX would need list of all entries as '#id'
      //  console.log(SVN_ENTRIES[j]);
      //  if(SVN_ENTRIES[j] !== undefined){
      //    $.tree.focused().create('#' + j);
      //    //remove the status, was committed (i.e 'M', or '?', '!', etc)
      //    //$.tree.focused().remove('#' + j);
      //    //console.log(CHECKED_FILE_NAMES[j]);
      //    //var ent = CHECKED_FILE_NAMES[j].replace(/.*?\s+/, STATUS_SPACER);
      //    //$.tree.focused().rename('#' + j, ent);

      //    // TREE_OBJ.create(false, TREE_OBJ.get_node(NODE[0]));
      //  }
      //   else {
      //    $.tree.focused().remove('#' + j, ent);
      //  }
      //}
    }
  }

  function change_display_selected_files(to_show){
    for(j=0;j<CHECKED_FILE_NAMES.length;j++){
      if(CHECKED_FILE_NAMES[j] !== undefined){
        //remove the status, was committed (i.e 'M', or '?', '!', etc)
        //$.tree.focused().remove('#' + j);
        //console.log(CHECKED_FILE_NAMES[j]);
        //var ent = CHECKED_FILE_NAMES[j].replace(/.*?\s+/, STATUS_SPACER);
        var ent = CHECKED_FILE_NAMES[j].replace(/.*?\s+/, to_show);
        //$.tree.focused().rename('#' + j, ent);
        $.tree.focused().remove('#' + j, ent);
      }
    }
  }


  //$("#show_repo").click(function () {
  //  if ($("#show_repo").attr('checked') == false){
  //    // dont show dir tree and no more work done
  //    $('#display_svn_repo_entries_tree').hide();
  //    return;
  //  }
  //});
  // the hide svn results gif
  $('a#hide_n_show').click(function(){
    if ( $("a#hide_n_show").html() == '[+]' ) {
       // our content
       $('#svn_action_results').show();
       // switch the +/- buttons
       $("#hide_n_show").html('[-]');
    }
    else if ($("a#hide_n_show").html() == '[-]') {
       // our content
       $('#svn_action_results').hide();
       // switch the +/- buttons
       $("a#hide_n_show").html('[+]');
    }
  });

  //$("#refresh_list").click(function () {
  //  window.location.reload();
  //  //history.go();
  //});

  function display_error_message(error){
    $("#svn_action_results").html('<p style="color:red">Error: '
                                     + error + '</p>');
  }

  // high level repo details
  function display_repo_info(r_info){
    var display =  'Repository: '  + r_info.svn_repo_master + '<br/>';
        display += 'User:&nbsp; '  + r_info.svn_user + '<br/>';
        display += 'Config File: ' + r_info.svn_repo_config_file + '<br/>';
       //r_info.repo_root_local_path
    $("#display_repo_info").html('<span style="color:blue">' + display 
                                                             + '</span><br/>');
  }
  //$('#display_repo_info').toggle(
  //  function () { $(this).css({"list-style-type":"disc", "color":"blue"}); }
  //);
  $("a#disp_repo_info").click(function() { $('#display_repo_info').toggle(); });


}); // end document.ready

