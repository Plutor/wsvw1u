package myVacuum;

sub BEGIN
{
  use DBI;
  use Exporter();
  @ISA = qw(Exporter);
  $VERSION = 0.90;
  @EXPORT = qw(%ARGS %USER $sanserif $B1 $B2 $W1 $W2
    &getArgs &connect_database &disconnect_database
    &check_password &check_cookies &user_field &fixformat
    &deny_nonusers &deny_nonmods &tabletop &mv_chomp
    &mysql_now &useractive &vertline &horizline
    &yearbooklink &fmttime);

  $sanserif = "Helvetica, Arial";
  $B1 = "<font color=\"#007f7f\"><b>";
  $B2 = "</b></font>";
  $W1 = "<font color=\"#ff0000\"><b>";
  $W2 = "</b></font>";
}

my (@goodtags) = ( 'B', 'U', 'I', 'A', 'BR' );

sub getArgs
{
  my ($post) = @_;

  #print STDERR "myVacuum.pm: getArgs(".scalar(@_).")\nmyVacuum.pm: $ENV{'CONTENT_LENGTH'} bytes\n";

  if (@_ < 1)
  {
    while (length $post < $ENV{'CONTENT_LENGTH'})
    {
      #print STDERR "myVacuum.pm: reading STDIN: \"$post\"\n";
      $post .= <STDIN>;
    }
  }

  (@args) = split(/&/, $post);
  foreach $arg (@args) {
    ($arg, $value) = split(/=/, $arg);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/ge;
    $ARGS{$arg} = $value;
  }
}

sub connect_database
{
  my($dbase_name) = "DBI:mysql:database=wsvw1u;host=localhost";
  my($database) = DBI->connect($dbase_name, "cgi", "cgi");
  return $database;
}

sub disconnect_database
{
  my ($database) = @_;
  $database->disconnect();  
}


sub check_password
{
  my ($name, $pass, $pass_status) = @_;
  my ($foo, $bar, $enc_pass);

  my $database = connect_database();                                                

  if ($pass_status eq "plain")
  {
    $foo = $database->prepare("SELECT password(?)");
    $foo->execute($pass);
    $bar = $foo->fetchrow_hashref();
    for (values %{$bar}) { $enc_pass = $_; }
    $foo->finish();
  }
  else
  {
    $enc_pass = $pass;
  }

  $foo = $database->prepare("SELECT * FROM users WHERE (name = ?) and (password = ?);"); 
  $foo->execute($name, $enc_pass); 
  $count = $foo->rows;
  $foo->finish();

  # Last Access
  $foo = $database->prepare("update users set lastaccess=now(),lastip=? where (name = ?);"); 
  $foo->execute($ENV{REMOTE_ADDR}, $name); 
  $foo->finish();

  disconnect_database($database);

  return ($count, $enc_pass);
}

sub check_cookies
{
  my($access, $cookie, $value, %COOK);

  my(@cookies) = split(/; /, $ENV{'HTTP_COOKIE'});
  foreach $cookie (@cookies) {
    ($cookie, $value) = split(/=/, $cookie);
    $value =~ tr/+/ /;
    $value =~ s/%([\dA-Fa-f][dA-Fa-f])/pack("C", hex($1))/eg;
    $COOK{$cookie} = $value;
  }
  ($access, $value) = check_password($COOK{'USERNAME'}, $COOK{'PASSWORD'}, "encrypted");

  if ($access == 1)
  {
    $USER{'name'} = $COOK{'USERNAME'};
    $USER{'pass'} = $COOK{'PASSWORD'};
  }
}

sub user_field
{
  my ($username, $field) = @_;

  my $database = connect_database();

  my $table = $database->prepare("SELECT * FROM users WHERE (name = ?)");
  $table->execute($username);
  if ($table->rows != 1) { $table->finish(); disconnect_database($database); return $undef; }

  my $row = $table->fetchrow_hashref();
  my $value = $row->{$field};

  $table->finish();
  disconnect_database($database);

  if ($value eq "") { return $undef; }
  return $value;
}

sub fixformat
{
  my($foo) = @_;

  # make returns into <br>s
  $foo =~ s/\r\n/<br>/g;
  $foo =~ s/\r/<br>/g;

  # turn 3+ returns into two
  $foo =~ s/<br>(<br>)+/<br><br>/g;

  # get rid of trailing returns
  $foo =~ s/(<br>)+$//g;

  # make the html happy
  $foo =~ s/<([^>]*)>/checkhtml($1)/sge;
  return($foo);
}

sub deny_nonusers
{
    my ($title) = @_;
    check_cookies();
    
    if (not defined($USER{'name'}))
    {
	require 'banner.pm';
      banner::top("$title");
	
	require 'vbox.pm';
      vbox::head(200, "Error", "ffffff");
      vbox::row("${W1}This feature is reserved for members only.${W2}  Please <a href=\"create.pl\">create</a> an account or <a href=\"login.pl?$ENV{'REQUEST_URI'}\">login</a> first.");
      vbox::foot();
      banner::bottom();
	exit;
  }
}

sub deny_nonmods
{
  my ($title) = @_;
  check_cookies();

  if ( (not defined($USER{'name'})) or (user_field($USER{'name'}, "moderator") ne "Y") )
  {
    require 'banner.pm';
    banner::top("$title");
	require 'vbox.pm';
      vbox::head(200, "Error", "ffffff");
      vbox::row("${W1}This feature is reserved for moderators only.${W2}");
      vbox::foot();
    banner::bottom();
    exit;
  }
}

sub checkhtml
{
    # i stole this code from SLASH 0.03

    my ($tag) = @_;

    $tag =~ s/^\s*?(.*)\s*?$/$1/e;

    if (uc(substr($tag,0,2)) eq 'A ')
    {
	$tag =~ s/^.*?href="?(.*?)"?$/A HREF="$1"/i; #enforce "
	return "<" . $tag . ">";
    }

    my $utag = uc $tag;
    foreach my $goodtag (@goodtags)
    {
	if ( ($utag eq $goodtag) || ($utag eq "/" . $goodtag) )
	{
	    return "<" . $utag . ">";
	}
    }
    return "&lt;$tag&gt;";
}

sub tabletop
{
  my ($width, $text, $sym) = @_;

  print "<table width=\"$width\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr valign=\"center\">";

  if (not defined $sym)
  {
      print "<td background=\"images/barbg.jpg\" align=\"left\" bgcolor=\"#007f7f\" width=\"14\"><img src=\"images/barleft2.jpg\" width=\"14\" height=\"44\"></td>";
  }
  else
  {
      print "<td background=\"images/barbg.jpg\" align=\"left\" bgcolor=\"#007f7f\" width=\"78\"><img src=\"images/barleft.jpg\" width=\"78\" height=\"44\"></td>";     
  }
  print "<td background=\"images/barbg.jpg\" align=\"left\" bgcolor=\"#007f7f\" width=\"100%\"><font color=\"#fffff0\"><b>$text</b></font></td>";
  print "<td background=\"images/barbg.jpg\" align=\"right\" bgcolor=\"#007f7f\" width=\"14\"><img src=\"images/barright.jpg\" width=\"14\" height=\"44\"></td>";
  print "</tr></table>";
}

sub mysql_now
{
  my ($dateonly) = @_;

  # Mon Jun 19 08:14:56 2000

  my %mnames = (Jan => 1, Feb => 2,
		Mar => 3, Apr => 4, 
		May => 5, Jun => 6,
		Jul => 7, Aug => 8,
		Sep => 9, Oct => 10,
		Nov => 11, Dec => 12);
  my @lt = split(/\s+/, localtime());
  
  return join('-', ($lt[4], $mnames{$lt[1]}, $lt[2]));
}

sub useractive
{
    my ($name) = @_;

    $db = connect_database();

    my $o = $db->prepare("select * from users where (name = ? and TO_DAYS(now()) - TO_DAYS(lastaccess) <= 30);");
    $o->execute($name);
    my $ret = $o->rows;
    $o->finish();
    disconnect_database($db);

    return $ret;
}

sub yearbooklink
{
    my ($name) = @_;

    return $name unless (useractive($name) and user_field($name, "yearbooking") eq "Y");

    return "<a href=\"yearbook.pl?" . $name . "\">" . $name . "</a>";
}

sub vertline
{
    my $h = "98%";

    print " <!-- vertline -->\n";
    print " <table height=\"$h\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\n";
    print " <tr height=\"$h\"><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"5\" height=\"1\"></td>\n";
    print " <td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td>\n";
    print " <td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"5\" height=\"1\"></td></tr>\n";
    print " </table>\n";
}

sub horizline
{
    my ($w) = @_;
    if ($w eq "") { $w = "98%"; }

    print " <!-- horizline -->\n";
    print " <table width=\"$w\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\n";
    print " <tr><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"1\" height=\"5\"></td></tr>\n";
    print " <tr><td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td></tr>\n";
    print " <tr><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"1\" height=\"5\"></td></tr>\n";
    print " </table>\n";
}

sub fmttime
{
    my ($time, $format) = @_;
    my @time = split(" ", $time);

    my @smon = ( Jan, Feb, Mar, Apr, May, Jun,
		 Jul, Aug, Sep, Oct, Nov, Dec );
    my @lmon = ( January, February, March, April, May, June, July,
		 August, September, October, November, December );

    my ($year, $mon, $day) = split("-", $time[0]);
    my ($hour, $min, $sec) = split(":", $time[1]);
    my $yr = sprintf("%02d", $year % 100);
    my $dy = sprintf("%d", $day);

    $format = user_field($USER{'name'}, "timeformat") if (not defined($format));

    my $ampm;
    if ($format % 2 == 0 and $format <= 6)
    {
	$ampm = ($hour >= 12) ? " PM" : " AM";
	$hour = $hour % 12;
	if ($hour == 0) { $hour = 12; }
    }

    return "$mon/$day/$yr \@ $hour:$min:$sec$ampm" if ($format == 1 or $format == 2);
    return "$hour:$min:$sec$ampm, $dy $smon[$mon-1] $year" if ($format == 3 or $format == 4);
    return "$hour:$min:$sec$ampm on $lmon[$mon-1] $dy, $year" if ($format == 5 or $format == 6);

    if ($format == 7)
    {
	use Time::Local;
	my $s = time() - timelocal($sec, $min, $hour, $day, $mon-1, $year-1900);
	if ($s == 0) { return "0 seconds ago"; }

	my $m = int($s/60);  $s = $s % 60;
	my $h = int($m/60);  $m = $m % 60;
	my $d = int($h/24);  $h = $h % 24;

	my @resp;
	push @resp, "$d days" if ($d > 0);
	push @resp, "$h hours" if ($h > 0);
	push @resp, "$m minutes" if ($m > 0);
	push @resp, "$s seconds" if ($s > 0);

	my $last = pop @resp;

	return join(", ", @resp) . ", and $last ago";
    }

    return $time;
}

sub END { }

return 1;


