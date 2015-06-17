package news;
BEGIN {
	use myVacuum;
}
END {}
return 1;

sub recent
{
  check_cookies();

  if (not defined($USER{'name'})) { $num = 6; }
    else { $num = user_field($USER{'name'}, "recent_news"); }

  my($post, $time, $entry, $author, $subject, $authmail, $id);

  print "<center>";

  my $database = connect_database();
  my $table = $database->prepare("SELECT * FROM news ORDER BY ID DESC");
  $table->execute();

  my ($foo);
  for ($foo=0; $foo<$num; $foo++)
  {
    my $thisrow = $table->fetchrow_hashref();

    if ($foo == $num-1) { show_hashref($thisrow, "yes"); }
      else { show_hashref($thisrow); }
  }
  
  $table->finish();
  disconnect_database($database);
  
  print "</center>\n";
}



sub older
{
  check_cookies();

  if (not defined($USER{'name'})) { $num = 6; }
    else { $num = user_field($USER{'name'}, "recent_news"); }

  my $database = connect_database();
  my $table = $database->prepare("SELECT * FROM news ORDER BY ID DESC");
  $table->execute();

  my ($foo);
  for ($foo=0; $foo<$num; $foo++)
  {
    my $thisrow = $table->fetchrow_hashref();
  }

  require "vbox.pm";
 vbox::head(150, "Older news");

  for ($foo=0; $foo<6; $foo++)
  {
    my $thisrow = $table->fetchrow_hashref();

    $subject = $thisrow->{'subject'};
    $id = $thisrow->{'ID'};

    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"respond.pl?$id\">$subject</a></font></td></tr>\n";
  }

    print "<tr valign=\"top\"><td><font size=\"-1\"><b>&raquo;</b></font></td><td width=\"100%\"><font size=\"-1\"><a href=\"archive.pl\"><b>Even older news</b></a></font></td></tr>\n";

 vbox::foot();

  $table->finish();
  disconnect_database($database);

}

sub show_hashref
{
  my ($hashref, $last) = @_;

  my $time = $hashref->{time};
  my $entry = $hashref->{entry};
  $entry =~ s/\r/<br>/g;
  my $author = $hashref->{author};
  my $subject = $hashref->{subject};
  my $id = $hashref->{ID};
  my $eds_note = $hashref->{eds_note};
  my $isevent = $hashref->{isevent};

  show($time, $author, $subject, $entry, $eds_note, $id, $last, $isevent);
}

sub show
{
  my ($time, $author, $subject, $entry, $eds_note, $id, $last, $isevent) = @_;

  $time = fmttime($time);

  print "<table width=\"98%\" cellpadding=\"3\" cellspacing=\"0\" border=\"0\">\n";

  print "<tr><td class=\"just\" colspan=\"2\"><b>$subject</b> " .
      "<font size=\"-1\">($time)</font><br>\n";
  print "<font face=\"$sanserif\" size=\"-1\"><b>&lt;";
  print yearbooklink($author);
  print "&gt;</b> </font>\n$entry\n";
  if (defined($eds_note) and ($eds_note ne ""))
  {
    print "<tt><i>[$eds_note -ed]</i></tt>";
  }
  print "</td></tr>\n";

  print "<tr><td>";
  if (defined $isevent and $isevent == 0)
  {
      print "<font size=\"-1\"><font color=\"#ff0000\">UNSCHEDULED EVENT</font>";
      print " (<a href=\"post.pl?setevent=$id\"><b>Set</b></a>)" if ($USER{name} eq $author or user_field($USER{name}, "moderator") eq "Y" );
      print "</font>";
  }
  elsif ($isevent > 0)
  {
      my @smon = ( Jan, Feb, Mar, Apr, May, Jun,
		   Jul, Aug, Sep, Oct, Nov, Dec );

      print "<font size=\"-1\"><font color=\"#ff0000\">SCHEDULED EVENT</font>";

      my $db = connect_database();
      my $t = $db->prepare("SELECT * FROM calendar WHERE (ID = ?);");
      $t->execute($isevent);
      my $r = $t->fetchrow_hashref;
      my $date = "<a href=\"calendar.pl?year=$r->{year}&month=$r->{month}&showday=$r->{day}\">" . $smon[$r->{month}-1] . " " . $r->{day} . "</a>";
      $t->finish(); disconnect_database($db);

      print " (<b>$date</b>";
      print " | <a href=\"post.pl?setevent=$id\">Set</a>" if ($USER{name} eq $author or user_field($USER{name}, "moderator") eq "Y");
      print ")</font>";
  }
  print "</td>\n";

  print "<td align=\"right\"><font size=\"-1\"><a href=\"respond.pl?$id\">Responses</a></font>";
  my $foo = count_responses($id);
  print "<tt>($foo)</tt>";
  print "</td></tr></table>";

  if (not defined ($last)) {
    print "<center><table width=\"98%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">";
    print "<tr><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"10\" height=\"5\"></td></tr>";
    print "<tr><td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"10\" height=\"1\"></td></tr>";
    print "<tr><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"10\" height=\"5\"></td></tr>";
    print "</table></center>";
  }
}

sub count_responses
{
  my($id) = @_;

  my $database = connect_database();

  my $sel = $database->prepare("SELECT * FROM responses WHERE (reference = ?);");
  $sel->execute($id);
  my $ret = $sel->rows;
  $sel->finish();

  disconnect_database($database);

  if ($ret eq "0E0") { $ret = "0"; }
  return $ret;
}
