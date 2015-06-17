package calendar;
BEGIN{
        use myVacuum;
	use POSIX 'strftime';
	$someEvent = 0;
}
END{}
return 1;


sub showdate {
  my ($julian, $y, $format) = @_;
  $re = "";

  # convert julian date to m/d/y gregorian(?)
  my $ly = (($y%4==0) and (not ($y%100==0) or ($y%400==0))) ? 1 : 0;
  $y += int(julian/(365+$ly));
  $julian = $julian % (365+$ly);
  my $m = 0;
  my @lmonths = (31, 28+$ly, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  while ($julian > $lmonths[$m]) { $julian -= $lmonths[$m++]; }
  $d = $julian; ++$m;

  my $db = connect_database();
  my $t = $db->prepare("SELECT * FROM calendar WHERE(month=? AND day=? AND (year=? or repeat_annual='Y'));");
  $t->execute($m, $d, $y);

  for (my $i=0; $i<$t->rows(); ++$i)
  {
    my $li;
    my $row = $t->fetchrow_hashref();
    if ($format eq 1)
    {
      my $wd = strftime("%a",0,0,0,$d,$m-1,$y-1900);
      $li = " (<a href=\"calendar.pl?year=$y&month=$m&showday=$d\">$wd</a>)";
    }
    elsif ($format eq 2)
    {
      my $wd = strftime("%b %e",0,0,0,$d,$m-1,$y-1900);
      $li = " (<a href=\"calendar.pl?year=$y&month=$m&showday=$d\">$wd</a>)";
    } else { $li = ""; }
    $re .= "<tr><td><font size=\"-1\">&not;</font></td>" .
           "<td width=\"100%\"><font size=\"-1\">$row->{title}$li</font></td></tr>\n";
  }
  $t->finish();
  disconnect_database($db);

  return $re;
}

sub upcoming {
    require 'vbox.pm';
    vbox::head(205, "Calendar");

  my $database = connect_database();

  my $julto = strftime "%j", localtime;
  my $year = strftime "%Y", localtime;

  # today
  if (my $re = showdate($julto, $year))
  {
    print "<tr><td colspan=\"2\"><font size=\"-1\"><font color=\"#ff0000\"><b>Today</b></font>";
    print strftime(" (<a href=\"calendar.pl?year=%Y&month=%m&showday=%d\">%a %b %d</a>)</td></tr>\n", localtime);
    print "$re";
    $someEvent = 1;
  }

  # tomorrow 
  if (my $re = showdate($julto+1, $year))  
  {
    my (undef, undef, undef, $day, $mon, $year) = localtime;
    use Date::Calc 'Add_Delta_Days';
    my ($year, $mon, $day) = Add_Delta_Days($year, $mon+1, $day, 1);
    my $now = strftime(" (<a href=\"calendar.pl?year=%Y&month=%m&showday=%d\">", 0, 0, 0, $day, --$mon, $year) .
    strftime("%a</a>)", 0, 0, 0, $day, $mon, $year);

    print "<tr><td colspan=\"2\"><font size=\"-1\"><font color=\"#ff0000\"><b>Tomorrow</b></font>$now</font></td></tr>\n";
    print "$re";
    $someEvent = 1;
  }

  # this week
  my $wre = "";
  for (my $dp = 2; $dp < 8; $dp++)
  {
    $wre .= showdate($julto+$dp, $year, 1)
  }
  if ($wre)
  {
    print "<tr><td colspan=\"2\"><font size=\"-1\" color=\"#ff0000\"><b>This week</b></font></font></td></tr>\n";
    print $wre;
    $someEvent = 1;
  }

  # no events..
  if ($someEvent == 0)
  {
      my $noe="";
      for ($dp = 8; $noe eq ""; $dp++)
      {
	  $noe = showdate($julto+$dp, $year, 2);
      }

    vbox::row("<center>No events within one week</center>");
    vbox::bar();
      
      print "<tr><td colspan=\"2\"><font size=\"-1\" color=\"#ff0000\"><b>Next event</b></font></td></tr>\n";
      print $noe;
  }

  disconnect_database($database);

  vbox::bar();
  print "<tr><td><center><font size=\"-1\"><a href=\"calendar.pl\">More..</font></center></td></tr>\n";
  vbox::foot();

}


