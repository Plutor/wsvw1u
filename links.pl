#!/usr/bin/perl

use myVacuum;
check_cookies();
getArgs();

sub main
{
    if ($USER{'name'} eq "log")
    {
	if ($ENV{'QUERY_STRING'} eq "add")
	{
	    addprompt();
	    exit;
	}
	elsif (defined $ARGS{'op'} and $ARGS{'op'} eq "Add")
	{
	    add();
	    exit;
	}
	elsif ($ENV{'QUERY_STRING'} =~ /^modify=(\d+)$/)
	{
	    modprompt($1);
	    exit;
	}
	elsif (defined $ARGS{'op'} and $ARGS{'op'} eq "Modify")
	{
	    modify();
	    exit;
	}
    }

    # You aren't cool-dee-oh Log, so you can only do these things
    if ($ENV{'QUERY_STRING'} =~ /^details=(\d+)$/)
    {
	details($1);
    }
    else
    {
	list();
    }
}

sub list
{
    my ($db, $table, $thisrow, @weeklist, $foo);
    my (@bar, $date, $year);
    my  %monthnum = (Jan => 1, Feb => 2, Mar => 3, Apr => 4,
		     May => 5, Jun => 6, Jul => 7, Aug => 8,
		     Sep => 9, Oct => 10, Nov => 11, Dec => 12);
    
    $db = connect_database();
    
    use POSIX 'strftime';
    require 'banner.pm';
  banner::top("links");
    
    require "vbox.pm";
    
    if ($USER{'name'} eq "log")
    {
        my $w = nextundefweek();
	
	$date = strftime("%m.%d.%y", localtime(909288000 + ($w * 604800)));

      vbox::head(400, "Log's Links of the Week");
	print "<tr><td align=\"right\" width=\"1\"><tt><b>$date</b></tt></td>";
	print "<td width=\"100%\" colspan=\"2\"><font size=\"-1\"><a href=\"links.pl?add\">";
	print "<b>Add Link</b></a></font></td></tr>\n";
      vbox::bar( ($w > thisweek() + 1) ? "cfcfcf" : "ffffff");
    }
    else
    {
      vbox::head(400, "Log's Links of the Week", "ffffff");
    }

    $table = $db->prepare("SELECT * FROM llotw ORDER BY WEEK DESC;");
    $table->execute();
    $count = $table->rows;
    for($foo=0; $foo<$count; $foo++)
    {
	$thisrow = $table->fetchrow_hashref();
	
	$date = strftime("%m.%d.%y", localtime(909288000 + ($thisrow->{'week'} * 604800)));
	
        if ( $thisrow->{'week'} > thisweek() )
        {
          if ($USER{'name'} ne "log") { $foo--; $count--; next; }
	  if ($foo != 0) { vbox::bar("cfcfcf"); }
        }
        else
        {
	  if ($foo != 0) { vbox::bar("ffffff"); }
        }
	print "<tr><td align=\"right\" width=\"1\"><tt>$date</tt></td>";
	print "<td width=\"100%\"><font size=\"-1\"><a href=\"$thisrow->{'url'}\">" .
	      "$thisrow->{'name'}</a></font></td><td align=\"right\">" .
	      "<font size=\"-2\"><a href=\"links.pl?details=$thisrow->{'week'}\">" .
	      "details</a></font></td></tr>\n";
    }

  vbox::foot();
  banner::bottom();
    
    $table->finish();
    disconnect_database($db);
}

sub thisweek
{
    my $r = int ((time() - 909288000) / 604800);

    return $r;
}

sub nextundefweek
{
    my $w;
    my $lastsun = thisweek()+1;
    my $cnt = 1;
    my $db = connect_database();
    for ($w = $lastsun; $cnt > 0; $w++)
    {
	$t = $db->prepare("SELECT * FROM llotw WHERE(week = ?);");
	$t->execute($w);
	$cnt = $t->rows();
  	#print STDERR "llotw.pl: Week $w, Count $cnt\n";
	$t->finish();
    }
    disconnect_database($db);

    return $w-1;
}

sub addprompt
{
    my ($mesg) = @_;

    my $w = nextundefweek();

    require "banner.pm";
  banner::top("links -> add");

    require "vbox.pm";
    print "<center>";
    print "$W1$mesg$W2\n" if (defined $mesg);
    print "<form action=\"links.pl\" method=\"post\">\n";
  vbox::head(400, "Add LLOTW (Week $w)", "ffffff");

  vbox::row("<center>${B1}Name${B2}:<br><input type=\"text\" name=\"name\" value=\"$ARGS{'name'}\" maxlength=\"80\" size=\"40\"></center>");
  vbox::row("<center>${B1}URL${B2}:<br><input type=\"text\" name=\"url\" value=\"$ARGS{'url'}\" maxlength=\"80\" size=\"40\"></center>");
  vbox::row("<center>${B1}Text${B2}:<br><textarea wrap=\"soft\" cols=\"40\" rows=\"10\" name=\"description\">$ARGS{'description'}</textarea></center>");
  vbox::row("<center>Propz:<br><input type=\"text\" name=\"propz\" value=\"$ARGS{'propz'}\" maxlength=\"40\" size=\"20\"></center>");

  vbox::bar("cfcfcf");
    print "<tr><td align=\"right\"><b>$USER{'name'}</b>'s password:</td>" .
	"<td><input type=\"password\" name=\"password\" width=\"10\" maxlength=\"10\"></td></tr>\n";
    print "<tr><td colspan=\"2\"><center><input type=\"submit\" value=\"Add\" name=\"op\"> " .
	"<input type=\"reset\" value=\"Reset\"></center></td></tr>";
    
  vbox::foot();
    print "</form></center>\n";
}

sub add
{
    my ($gp) = check_password($USER{'name'}, $ARGS{'password'}, "plain");
    if ( not $gp )
    {
	addprompt("Incorrect password");
	exit;
    }

    if ($ARGS{'name'} eq "" or
	$ARGS{'url'} eq "" or
	$ARGS{'description'} eq "")
    {
	addprompt("Incomplete data");
	exit;
    }

    my $w = nextundefweek();

    my $db = connect_database();
    my $ins = $db->prepare("INSERT INTO llotw(week, url, name, description, propz) VALUES(?, ?, ?, ?, ?);");
    $ins->execute($w, $ARGS{'url'}, $ARGS{'name'}, $ARGS{'description'}, $ARGS{'propz'});

    require 'banner.pm';
  banner::top("moderate", "2;URL=links.pl");
    if ($ins->rows() == 1)
    {
      print "<center>Link successfully added.</center>";
    }
    else
    {
      print "<center>Error adding link.</center>";
    }
  banner::bottom();

    $ins->finish();
    disconnect_database($db);
}

sub details
{
    my ($w) = @_;

    my $db = connect_database();
    my $ins = $db->prepare("SELECT * FROM llotw WHERE (week = ?);");
    $ins->execute($w);
    my $r = $ins->fetchrow_hashref();

    require "banner.pm";
    banner::top("links -> details -> $w");

    print "<center>";
    require "vbox.pm";

    vbox::head(400, "Link for week $w", "ffffff");
    vbox::row("<b><a href=\"$r->{'url'}\">$r->{'name'}</a></b> - " .
              "$r->{'description'}" .
              (($r->{'propz'} ne "") ? " (<i>Propz to $r->{'propz'}</i>)" : "") );

    if ($USER{'name'} eq "log")
    {
      vbox::bar();
      vbox::row("<center><a href=\"links.pl?modify=$w\"><font size=\"-1\">Modify</font></a></center>");
    }

    vbox::foot();

    banner::bottom();
    $ins->finish();
    disconnect_database($db);
}

sub modprompt
{
    my ($w, $mesg) = @_;

    my $db = connect_database();
    my $ins = $db->prepare("SELECT * FROM llotw WHERE (week = ?);");
    $ins->execute($w);
    my $r = $ins->fetchrow_hashref();

    require "banner.pm";
  banner::top("links -> modify -> $w");

    require "vbox.pm";
    print "<center>";
    print "$W1$mesg$W2\n" if (defined $mesg);
    print "<form action=\"links.pl\" method=\"post\">\n";
    print "<input type=\"hidden\" name=\"week\" value=\"$w\">\n";
  vbox::head(400, "Modify LLOTW (Week $w)", "ffffff");

  vbox::row("<center>${B1}Name${B2}:<br><input type=\"text\" name=\"name\" value=\"$r->{'name'}\" maxlength=\"80\" size=\"40\"></center>");
  vbox::row("<center>${B1}URL${B2}:<br><input type=\"text\" name=\"url\" value=\"$r->{'url'}\" maxlength=\"80\" size=\"40\"></center>");
  vbox::row("<center>${B1}Text${B2}:<br><textarea wrap=\"soft\" cols=\"40\" rows=\"10\" name=\"description\">$r->{'description'}</textarea></center>");
  vbox::row("<center>Propz:<br><input type=\"text\" name=\"propz\" value=\"$r->{'propz'}\" maxlength=\"40\" size=\"20\"></center>");

  vbox::bar("cfcfcf");
    print "<tr><td align=\"right\"><b>$USER{'name'}</b>'s password:</td>" .
	"<td><input type=\"password\" name=\"password\" width=\"10\" maxlength=\"10\"></td></tr>\n";
    print "<tr><td colspan=\"2\"><center><input type=\"submit\" value=\"Modify\" name=\"op\"> " .
	"<input type=\"reset\" value=\"Reset\"></center></td></tr>";
    
  vbox::foot();
    print "</form></center>\n";

    $ins->finish();
    disconnect_database($db);
}

sub modify
{
    my $w = $ARGS{'week'};

    my ($gp) = check_password($USER{'name'}, $ARGS{'password'}, "plain");
    if ( not $gp )
    {
	modprompt($w, "Incorrect password");
	exit;
    }

    if ($ARGS{'name'} eq "" or
	$ARGS{'url'} eq "" or
	$ARGS{'description'} eq "")
    {
	modprompt($w, "Incomplete data");
	exit;
    }

    my $db = connect_database();
    my $old = $db->prepare("SELECT * FROM llotw WHERE (week = ?);");
    $old->execute($w);
    my %o = %{$old->fetchrow_hashref()};

    my $fail = 0;

    foreach (keys %o)
    {
	#print STDERR "$_\n";
	if ($o{$_} ne $ARGS{$_})
	{
	    my $u = $db->prepare("UPDATE llotw SET $_=? WHERE (week=?);");
	    $u->execute($ARGS{$_}, $w);
	    if ($u->rows() != 1) { $fail = 1; last; }
	    $u->finish();
	}
    }

    $old->finish();

    require 'banner.pm';
  banner::top("moderate", "2;URL=links.pl");
    if (not $fail)
    {
      print "<center>Link successfully modified.</center>";
    }
    else
    {
      print "<center>Error adding link.</center>";
    }
  banner::bottom();

    disconnect_database($db);
}



main;
