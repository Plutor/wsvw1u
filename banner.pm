package banner;
BEGIN {
  use myVacuum;
  check_cookies();
}
END {}
return 1;

sub top {
    my ($title, $refresh, $ssi) = @_;
    $title = (($ENV{'REQUEST_URI'} =~ /\/dev/) ? "dev." : "") . ((not defined($title)) ? "wsvw1u.com" : "wsvw1u -> $title");
    
    if ($ssi ne "SSI")
    {
	print "Content-type: text/html\n\n";
	print "<html>\n";
    }
    print "<head>\n";
    if (defined($refresh)) { print "<meta http-equiv=\"Refresh\" content=\"$refresh\">\n"; }
    
    $subtitle = randomsubtitle();

print <<_END_OF_HEAD_;
<meta http-equiv="Pragma" content="no-cache">
<meta name="keywords" content="WSVW1U, Vacuum, NVAD, NVAD97, NVAD98, NVAD99, NVAD00, NVAD01, Vacuums, leet">
<title>$title</title>

<style type="text/css">
<!--
    a        { text-decoration: none }
    a:hover  { text-decoration: underline }

    td.just  { text-align: justify }
-->
</style>

</head>
<body bgcolor="#ffffff" link="#0000ef" vlink="#0000ef" leftmargin="0" topmargin="0" rightmargin="0" marginheight="0" marginwidth="0">

<!-- *** top banner *** -->
<map name="banvad">
 <area shape="rect" coords="0,0,46,50" href="nvad/01/order.html">
 <area shape="rect" coords="46,0,327,50" href="index.pl">
</map>

<table border="0" cellpadding="3" cellspacing="0" width="100%">
  <tr bgcolor="#007f7f"><td background="images/banbg.jpg" colspan=\"2\">
    <img src="images/banvad.gif" border="0" usemap="#banvad">
    <font color="#fffff0">&nbsp;
    <tt>+: $subtitle</tt></font>
  </td></tr>
  <!-- *** menu bar *** -->
  <tr bgcolor="#007f7f" valign="center"><td background="images/menubg.jpg" height="35">
    <tt><font color="#000000">&nbsp;
    <a href="index.pl"><font color="#ffcf00"><b>Home</b></font></a> | 
    <a href="/nvad/"><font color="#ffcf00"><b>NVAD</b></font></a> | 
    <a href="camera.pl"><font color="#ffcf00"><b>Cameras</b></font></a> | 
_END_OF_HEAD_
    
    if (defined $USER{'name'}) {
	print "<b><a href=\"settings.pl\"><font color=\"#ffcf00\">Settings</font></a></b> | \n",
	"<b><a href=\"logout.pl\"><font color=\"#ffcf00\">Logout</font></a></b> | \n";
    } else {
	print "<b><a href=\"create.pl\"><font color=\"#ffcf00\">Create User</font></a></b> | \n",
	"<b><a href=\"login.pl?$ENV{'REQUEST_URI'}\"><font color=\"#ffcf00\">Login</font></a></b> | \n";
    }
    
    print "<b><a href=\"archive.pl\"><font color=\"#ffcf00\">Search</font></a></b> | \n";
    print "<b><a href=\"help.pl\"><font color=\"#ffcf00\">Help</font></a></b>\n";
    print "</font></tt></td>\n";

    use POSIX 'strftime';
    my $datestr = strftime("%d %B %Y", localtime);
    print "<td align=\"right\" background=\"images/menubg.jpg\" height=\"35\">\n";
    print "$datestr</td>\n";

    print "</tr></table>\n";
}

sub bottom
{
  print "<table border=\"0\" cellpadding=\"0\" width=\"100%\">";       
  print "<tr bgcolor=\"#000000\"><td><img src=\"images/spacer.gif\" height=\"1\" width=\"10\"></td></tr>\n";
  print "<tr><td><font size=\"-1\">&nbsp;";

  print "<a href=\"stats\">stats</a> "; 
  print "| <a href=\"mailto:log\@wsvw1u.com\">bug report</a> ";
  print "| <a href=\"resume.shtml\">resume</a> ";
  print "| <a href=\"schedule.shtml\">schedule</a></font></td></tr>";
  print "</table>\n\n";
  print "</body>\n</html>\n"; 
}

sub randomsubtitle
{
    return "Klaatu, Barada, Nikto" if (not defined $USER{'name'});

    open (IN, "subs.txt") or return "What happened to my data file?";
    while (<IN>)
    {
	push @s, $_;
    }
    close IN;

    srand($$ ^ time);
    my $r = $s[ rand(@s) ];

    $r =~ s/\%UN/$USER{'name'}/g;

    return $r;
}
