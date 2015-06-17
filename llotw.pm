package llotw;
BEGIN { use myVacuum; }
END {}
return 1;

sub this
{
  my ($database, $table, $thisrow, @weeklist, $foo);

  $database = connect_database();

  $table = $database->prepare("SELECT FLOOR((TO_DAYS( NOW() ) - TO_DAYS( '1998-10-25 00:00:00' )) / 7);");
  $table->execute();
  $thisrow = $table->fetchrow_hashref();
  for (values %{$thisrow}) { $thisweeknum = $_; }
  $table->finish();

  require "vbox.pm";
 vbox::head(150, "Log's Link");

  $table = $database->prepare("SELECT * FROM llotw WHERE (week = ?);");
  $table->execute($thisweeknum);

  if ($table->rows != 1)
  {
    $table->finish();
    $table = $database->prepare("SELECT * FROM llotw;");
    $table->execute();
    for(my $foo=0; $foo<$table->rows; $foo++)
    {
      $thisrow = $table->fetchrow_hashref();
      push(@weeklist, $thisrow->{'week'});
    }
    $table->finish();
    srand(time ^ $$);  $thisweeknum = $weeklist[rand($#weeklist)];
    $table = $database->prepare("SELECT * FROM llotw WHERE (week = ?);");
    $table->execute($thisweeknum);
    $thisrow = $table->fetchrow_hashref();
    $thisrow->{'description'} = "<b>Random lazy copout $thisweeknum:</b><br>" .
	$thisrow->{'description'};
  }
  else
  {
    $thisrow = $table->fetchrow_hashref();
  }
  
  my $propz = yearbooklink($thisrow->{'propz'});

 vbox::row("<font size=\"-1\">$thisrow->{'description'}" . 
	   ( ($thisrow->{'propz'} ne "") ? " (<i>Propz to $propz</i>)" : "") .
	   "</font>");

 vbox::bar();

  print "<tr><td><A href=\"$thisrow->{'url'}\"><font size=\"-1\" face=\"$sanserif\">$thisrow->{'name'}</font></A></td>";
  print "<td><A href=\"links.pl\"><IMG src=\"images/links.gif\" align=\"right\" border=\"0\" width=\"14\" height=\"15\"></A></td></tr></table>";

 vbox::foot();

  $table->finish();
  disconnect_database($database);
}

