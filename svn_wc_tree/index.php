<?php

  $cgi_script = dirname(__FILE__) . '/svn_wc_broker.cgi';
  $args = $_REQUEST;
  //__debug_args__($args);

  header('Content-Type: application/x-javascript; charset=UTF-8');
  $a1 = 'do_svn_action='.urlencode($args['do_svn_action']);
  $a2 = 'svn_action='.urlencode($args['svn_action']);
  $a3 = 'svn_files='.urlencode($args['svn_files']);
  //passthru("$cgi_script $a1 $a2 $a3");

  $a1 = escapeshellarg($a1);
  $a2 = escapeshellarg($a2);
  $a3 = escapeshellarg($a3);

  passthru("$cgi_script $a1 $a2 $a3");


  //emergency use only!
  function __debug_args__($args){
    $debug = "/tmp/DEBUG";
    $fh = fopen($debug, 'w') or die("can't open file");
    fwrite($fh, print_r($args, true));
    //fwrite($fh, $args['do_svn_action']);
    fclose($fh);
  }

?>
