#!/usr/bin/perl

use myVacuum;
getArgs();

sub main
{
  my ($table, $id, $database, $count);

  $id = $ENV{'QUERY_STRING'};

  $database = connect_database();
  $table = $database->prepare("SELECT * FROM camera WHERE (name = ?);");
  $table->execute($id);
  if ($table->rows != 1)
  {
    $table->finish();
    $table->execute("log");
  }

  show_cam($table->fetchrow_hashref());
  $table->finish();
  disconnect_database($database);
}

sub show_cam
{
    my ($hashref) = @_;

    $name = $hashref->{'name'};
    $url_pic = "<img src=\"" . $hashref->{'url_pic'} . "\" border=\"0\">";
    if (defined($hashref->{'urllink'})) {
	$url_pic = "<a href=\"" . $hashref->{'urllink'} . "\">" . $url_pic . "</a>";
    }
    $refresh = $hashref->{'refresh'};
    
    require 'banner.pm';
  banner::top("camera -> $name", $refresh);
    
    require 'vbox.pm';
  vbox::head(400, "Live ${name}cam", "ffffff");

  vbox::row("<center>$url_pic<br>" .
	    "<font size=\"-1\">This image will refresh in ${W1}$refresh${W2} " .
	    "seconds</font></center>\n");


  vbox::bar();

    my $database = connect_database();
    my $table = $database->prepare("SELECT * FROM camera ORDER BY name;");
    $table->execute();
    $thisrow = $table->fetchrow_hashref();

    my $cheight = $table->rows / 4;
    $cheight = ($cheight == int $cheight) ? $cheight : int $cheight + 1;
    my $foo = 0;
    print "<tr valign=\"top\"><td>\n";
    while (defined($thisrow))
    {
	my $sym = ($thisrow->{'name'} eq $hashref->{'name'}) ? "&raquo;" : "&not;";
	print "<font size=\"-1\" color=\"#000000\">$sym&nbsp;" .
	    "<a href=\"camera.pl?$thisrow->{'name'}\">$thisrow->{'name'}</a></font><br>\n";
	if (++$foo != $table->rows and $foo % $cheight == 0) { print "</td>\n<td>"; }
	$thisrow = $table->fetchrow_hashref();
    }
    print "</font></td></tr>\n";
    $table->finish();
    disconnect_database($database);
    
  vbox::foot();
    
  banner::bottom();
}


main;
