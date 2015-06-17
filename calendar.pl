#!/usr/bin/perl

use myVacuum;
use POSIX 'strftime';
getArgs();
getArgs($ENV{'QUERY_STRING'});
check_cookies();

sub main
{
  my $thismonth = strftime "%m", localtime;
  my $thisyear = strftime "%Y", localtime;
  my $year = $ARGS{'year'} = $ARGS{'year'} || $thisyear;
  my $month = $ARGS{'month'} = $ARGS{'month'} || $thismonth;

  if ($month > 12) { $month=12; }
  if ($month < 1) { $month=1; }

  require 'banner.pm';
  banner::top("calendar");

  if ( defined $ARGS{'showday'} )
  {
    showday($month, $year, $ARGS{'showday'});
  }
  elsif ( defined $ARGS{'delete'} )
  {
    delsubmit($ARGS{'delete'});
  }
  elsif ( defined $ARGS{'modify'} )
  {
    if (not defined $ARGS{'mod'})
    {
      modprompt($ARGS{'modify'})
    }
    else
    {
      modsubmit($ARGS{'modify'}, $ARGS{'day'}, $month, $year,
        $ARGS{'title'}, $ARGS{'desc'}, $ARGS{'author'});
    }
  }
  else
  {
    if ( defined $ARGS{'add'} and defined $USER{'name'} )
    {
      if ( $ARGS{'add'} eq "prompt" )
      {
        addprompt($month, $year)
      }
      elsif ( $ARGS{'add'} eq "Add" )
      {
        addsubmit($ARGS{'day'}, $month, $year,
          $ARGS{'title'}, $ARGS{'desc'});
      }
    }

    if ( ($month == $thismonth) and ($year == $thisyear) )
    {
      showmonth($month, $year, strftime "%d", localtime);
    }
    else
    {
      showmonth($month,$year);
    }
  }

  banner::bottom("calendar");
}

sub showmonth
{
  my ($month, $year, $today) = @_;
  my ($foo);

  my $firstday = strftime "%w", 0, 0, 0, 1, $month-1, $year-1900;
  my $title = strftime "%B %Y", 0, 0, 0, 1, $month-1, $year-1900;
  my $monlen = lengthofmonth($month, $year);

  $db = connect_database();
  
  # get all events within the month
  $events = $db->prepare("SELECT * FROM calendar WHERE ( month=? AND (year=? OR repeat_annual='Y') ) ORDER BY day;");
  $events->execute($month, $year);
  $currow = $events->fetchrow_hashref();

  print "<center>";
  #tabletop(620, $title);
  print "<table bgcolor=\"#000000\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td>";

  print "<table cellpadding=\"3\" cellspacing=\"2\" ";
  print "border=\"0\">\n";
  print "<tr bgcolor=\"#007f7f\"><td colspan=\"7\"><center><b>$title</b></center></td></tr>\n";
  print "<tr bgcolor=\"#ffffff\"><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th>";
  print "<th>Thursday</th><th>Friday</th><th>Saturday</th></tr>\n";

  # first week
  print "<tr bgcolor=\"#ffffff\">";
  for ($foo=0; $foo<7; $foo++)
  {
    if ($foo <= $firstday-1)
    {
      print "<td width=\"80\">&nbsp;</td>";
    }
    else
    {
      my $day = $foo - $firstday + 1;
      dayinmonth($day, $today);
    }
  }
  print "</tr>\n";

  # middle weeks
  for ($sun=8-$firstday; $sun<$monlen-6; $sun+=7)
  {
    print "<tr bgcolor=\"#ffffff\">";
    for ($foo=$sun; $foo<$sun+7; $foo++)
    {
      dayinmonth($foo, $today);
    }
    print "</tr>\n";
  }

  # last week
  print "<tr bgcolor=\"#ffffff\">";
  for ($foo=$sun; $foo<$sun+7; $foo++)
  {
    if ($foo >= $monlen+1)
    {
      print "<td width=\"80\">&nbsp;</td>";
    }
    else
    { 
      dayinmonth($foo, $today);
    }
  }
  print "</tr></table>\n";
  print "</td></tr></table>";

  my $prevmon = $month-1; my $pyear = $year;
  if ($prevmon < 1) { $pyear--; $prevmon=12; }
  $title = strftime "%B %Y", 0, 0, 0, 1, $prevmon-1, $pyear-1900;
  print "<a href=\"calendar.pl?month=$prevmon&year=$pyear\">&lt;&lt; $title</a> | ";

  if (defined $USER{'name'})
  {
    print "<a href=\"calendar.pl?month=$month&year=$year&add=prompt\"><b>add</b></a> | ";
  }

  my $nextmon = $month+1; my $nyear = $year;
  if ($nextmon > 12) { $nyear++; $nextmon=1; }
  $title = strftime "%B %Y", 0, 0, 0, 1, $nextmon-1, $nyear-1900;
  print "<a href=\"calendar.pl?month=$nextmon&year=$nyear\">$title &gt;&gt;</a><br>\n";

  print "<form action=\"calendar.pl\" method=\"get\"><select name=\"month\">\n";
  for ($foo=0; $foo<12; $foo++)
  {
    my $mname = strftime "%B", 0, 0, 0, 1, $foo, 100;
    my $mnum = $foo+1;
    if ($mnum==$month) { $s="selected"; } else { $s=""; }
    print "  <option $s value=\"$mnum\">$mname</option>\n";
  }
  print "</select><select name=\"year\">";
  for ($foo=1994; $foo<2010; $foo++)
  {
    if ($foo==$year) { $s="selected"; } else { $s=""; }
    print "  <option $s>$foo</option>\n";
  }
  print "</select> <input type=\"submit\" value=\"jump\"></form>\n";

  print "</center>";
  $events->finish();
  disconnect_database($db);
}


sub dayinmonth
{
  my ($day, $today) = @_;
  my $ev = "<br>";
  my $numinday;

  $dnevent = $currow->{day};
  while ($dnevent == $day)
  {
    my $t = substr($currow->{title}, 0, 8);
    if ($currow->{repeat_annual} eq 'Y') { $t = "<i>" . $t . "</i>"; }
    if (length $currow->{title} > 8) { $t .= ".."; }
    if ($numinday++ < 3)
    {
      $ev .= "&middot; $t<br>";
    }
    $currow = $events->fetchrow_hashref();
    $dnevent = $currow->{'day'};
  }
  if ($numinday > 0) { $dayshw = "<a href=\"calendar.pl?year=$ARGS{'year'}&month=$ARGS{'month'}&showday=$day\">$day</a>"; }
    else { $dayshw = "$day"; }
  while ($numinday++ < 3) { $ev .= "<br>"; }

  if ($day == $today)
  {
    print "<td width=\"80\" valign=\"top\"><font color=\"#ff0000\"><b>$dayshw</b>$ev</font></td>";
  }
  else
  {
    print "<td width=\"80\" valign=\"top\">$dayshw$ev</td>";
  }
}

sub lengthofmonth
{
  my ($month, $year) = @_;

  my $ret = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month-1];
  if ($month == 2)
  {
    if ($year % 4 == 0)   { $ret++ }
    if ($year % 100 == 0) { $ret-- }
    if ($year % 400 == 0) { $ret++ }
  }

  return $ret;
}

sub addprompt
{
    my ($month, $year) = @_;
    my ($foo);
    
    my $monthname = strftime "%B", 0, 0, 0, 1, $month-1, $year-1900;
    
    require 'vbox.pm';
    print "<center><form action=\"calendar.pl\" method=\"post\">\n";
    
  vbox::head(400, "Add event");
    print "<tr><td><center>";
    print "<input type=\"hidden\" name=\"month\" value=\"$month\">$monthname\n";
    print "<select name=\"day\">";
    for ($foo=1; $foo<=lengthofmonth($month,$year); $foo++)
    {
	print "<option>$foo</option>";
    }
    print "</select>\n";
    print "<input type=\"hidden\" name=\"year\" value=\"$year\">, $year<br>\n";
    
    print "Event title:<br><input type=\"text\" name=\"title\" size=\"41\" maxlength=\"40\"><br>";
    print "Description:<br><textarea cols=\"40\" rows=\"10\" wrap=\"soft\" name=\"desc\"></textarea></td></tr>\n";
  vbox::bar();
    print "<tr><td><center><input type=\"radio\" name=\"repeat\" value=\"none\" checked> Do not repeat</center></td><td><center><input type=\"radio\" name=\"repeat\" value=\"year\"> Repeat every year</center></td></tr>\n";

vbox::bar();
vbox::row("<center><input type=\"submit\" name=\"add\" value=\"Add\"></center>");
vbox::foot();

print "</form></center>\n";
}

sub addsubmit
{
  my ($day, $month, $year, $title, $desc) = @_;

  $rep = ($ARGS{'repeat'} eq "none") ? 'N' : 'Y';

  $db = connect_database();
  $events = $db->prepare("INSERT INTO calendar (author, title, repeat_annual, description, month, day, year) VALUES (?, ?, ?, ?, ?, ?, ?);");
  $events->execute($USER{'name'}, $title, $rep, $desc, $month, $day, $year);

  if ($events->rows > 0)
  {
    print "<center>${W1}Added event successfully$W2</center><br>";
  }
  else
  {
    print "<center>${W1}Failure$W2</center><br>";
  }

  $events->finish();
  disconnect_database($db);
}

sub showday
{
  my ($month, $year, $day) = @_;
  my ($foo);

  $db = connect_database();
  my $ev = $db->prepare("SELECT * FROM calendar WHERE (month=? AND day=? AND (year=? OR repeat_annual='Y') );");
  $ev->execute($month,$day,$year);

  if ($ev->rows == 0) { $ev->finish(); disconnect_database($db); showmonth($month, $year); return; }

  require 'vbox.pm';
  vbox::head(500, strftime("%d %B %Y", 0, 0, 0, $day, $month-1, $year-1900), "ffffff");

  for ($foo=0; $foo<$ev->rows; $foo++)
  {
        my $thisrow = $ev->fetchrow_hashref();

        print "<tr><td><b>$thisrow->{'title'}</b>";
	print " [<font size=\"-1\" color=\"#ff0000\"><b>ANNUAL</b></font>]" if ($thisrow->{repeat_annual} eq "Y");
	print "<br>\n<font face=\"$sanserif\" size=\"-1\"><b>&lt;";
	print yearbooklink($thisrow->{'author'});
	print "&gt;</b> </font>\n$thisrow->{'description'}</td></tr>\n";
	
	if ( ($thisrow->{'author'} eq $USER{'name'}) or (user_field($USER{'name'}, "moderator") eq "Y") )
	{
	  vbox::bar();
	  vbox::row("<center>admin: [<a href=\"calendar.pl?modify=$thisrow->{'ID'}\">modify</a> | " .
		    "<a href=\"calendar.pl?delete=$thisrow->{'ID'}\">delete</a>]</center>");
	}
	
	vbox::bar("ffffff");
    }

  my $mn = strftime("calendar.pl?month=%m&year=%Y\">%B %Y", 0, 0, 0, $day, $month-1, $year-1900);
  vbox::row("<center><font size=\"-1\"><b>Back to <a href=\"$mn</a><b></font></center>");
  vbox::foot();
}

sub modprompt
{
  my ($id) = @_;
  my ($foo);


  $db = connect_database();
  my $ev = $db->prepare("SELECT * FROM calendar WHERE (ID = ?);");
  $ev->execute($id);
  my $tr = $ev->fetchrow_hashref();

  my ($year, $month, $day) = split(/-/, $tr->{'date'});
  if ( ($tr->{'author'} ne $USER{'name'}) and (user_field($USER{'name'}, "moderator") ne "Y") )
  {
    $ev->finish(); disconnect_database(); showday($month, $year, $day); return;
  }

  print "<center>";
  print "<form action=\"calendar.pl\" method=\"post\">\n";
  print "<input type=\"hidden\" name=\"modify\" value=\"$id\">";
  require 'vbox.pm';
  vbox::head(400, "Modify event");

  print "<tr><td><center><select name=\"month\">\n";
  for ($foo=1; $foo<=12; $foo++)
  {
    my $mn = strftime "%B", 0, 0, 0, 1, $foo-1, 0;
    print "  <option value=\"$foo\"";
    if ($foo == $month) { print " selected"; }
    print ">$mn\n";
  }
  print "</select> <select name=\"day\">\n";
  for ($foo=1; $foo<=lengthofmonth($month,$year); $foo++)
  {
    print "  <option";
    if ($foo == $day) { print " selected"; }
    print ">$foo</option>\n";
  }
  print "</select>\n";
  print "<input type=\"hidden\" name=\"year\" value=\"$year\"> $year</center></td></tr>\n";

  vbox::row("<center>Event title:<br><input type=\"text\" name=\"title\" size=\"41\" maxlength=\"40\" value=\"$tr->{'title'}\"></center>");
  vbox::row("<center>Description:<br><textarea cols=\"40\" rows=\"10\" wrap=\"soft\" name=\"description\">$tr->{'description'}</textarea></center>");
  vbox::bar();
  
  print "<tr><td><center><input type=\"radio\" name=\"repeat\" value=\"none\"";
  print (($tr->{repeat_annual} eq "N") ? " checked" : "");
  print "> Do not repeat</center></td><td><center><input type=\"radio\" name=\"repeat\" value=\"year\"";
  print (($tr->{repeat_annual} eq "Y") ? " checked" : "");
  print "> Repeat every year</center></td></tr>\n";

  vbox::bar();
  vbox::row("<center><input type=\"reset\" value=\"reset\"> <input type=\"submit\" name=\"mod\" value=\"modify\"></center>");

  vbox::foot();

  print "</form></center>\n";

  $ev->finish();
  disconnect_database($db);
}

sub modsubmit
{
  my ($id, $day, $month, $year, $title, $desc, $author) = @_;

  $db = connect_database();
  my $ev = $db->prepare("SELECT * FROM calendar WHERE (ID = ?);");
  $ev->execute($id);
  my $tr = $ev->fetchrow_hashref();
  if ( ($tr->{'author'} ne $USER{'name'}) and (user_field($USER{'name'}, "moderator") ne "Y") )
  {
    $ev->finish(); disconnect_database(); showday($month, $year, $day); return;
  }
  $ev->finish();

  foreach my $el (qw(description title month day))
  {
    if ($tr->{$el} ne $ARGS{$el}) {
      $ev = $db->prepare("UPDATE calendar SET $el=? WHERE (ID = ?);");
      $ev->execute($ARGS{$el}, $id);
      last if ($ev->rows() == 0);
      $ev->finish();
    }
  }
  if ($ARGS{repeat} eq "year")
  {
    $ev = $db->prepare("UPDATE calendar SET repeat_annual=? WHERE (ID = ?);");
    $ev->execute(($ARGS{repeat} eq "year") ? "Y" : "N", $id);
    $ev->finish();
  }

  if ($ev->rows != 0)
  {
    print "<center>${W1}Modified event successfully$W2</center><br>";
  }
  else
  {
    print "<center>${W1}Failure$W2</center><br>";
  }

  $ev->finish();
  disconnect_database($db);

  showday($month, $year, $day);
}

sub delsubmit
{
  my ($id) = @_;

  $db = connect_database();
  $events = $db->prepare("SELECT * FROM calendar WHERE (ID = ?);");
  $events->execute($id);
  my $tr = $events->fetchrow_hashref();
  if ( ($tr->{'author'} ne $USER{'name'}) and (user_field($USER{'name'}, "moderator") ne "Y") )
  {
    $ev->finish(); disconnect_database(); showday($month, $year, $day); return;
  }
  $events->finish();

  $events = $db->prepare("DELETE FROM calendar WHERE (ID = ?);");
  $events->execute($id);

  if ($events->rows == 1)
  {
    print "<center>${W1}Deleted event successfully$W2</center><br>";
  }
  else
  {
    print "<center>${W1}Failure$W2</center><br>";
  }

  $events->finish();
  disconnect_database($db);

  showday($tr->{month}, $tr->{year}, $tr->{day});
}






my ($currow, $db, $events);
main;

