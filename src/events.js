var mHealthToken = '';
$('[data-role=page]#selection').live('pageshow', function( ev, data) {
  mHealthToken = window.location.hash.match("=.*")[0].substring(1);
  $.mobile.changePage($('#selection'));
});
