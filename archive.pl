#!/usr/bin/perl

use myVacuum;
getArgs($ENV{'QUERY_STRING'});

sub main
{
  if (defined($ARGS{'search'}))
  {
    search($ARGS{'author'}, $ARGS{'text'}, $ARGS{'min'}, $ARGS{'max'});
  }
  else
  {
    list();
  }

}

sub list
{
  my ($msg) = @_;
  my ($database, $count, $table, $foo, $thisrow);

  $database = connect_database();

  $table = $database->prepare("SELECT * FROM news ORDER BY ID DESC");
  $table->execute();
  $count = $table->rows;

  require 'banner.pm';
  banner::top("archive");

  print "<table cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n";
  print "<tr valign=\"top\" bgcolor=\"#ffffff\"><td width=\"310\">";
  searchprompt($ARGS{'author'}, $ARGS{'text'}, $ARGS{'in'});

  print "</td><td width=\"1\" bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\" height=\"10\"></td><td>\n";

  tabletop(300, "Archive");
  print "<table width=\"300\" cellpadding=\"0\">";

  if (defined($msg))
  {
    print "<tr><td></td><td><tt><font color=\"#ff0000\">&nbsp;<b>$msg</b></font></tt><br></td></tr>";
  }
  for ($foo=0; $foo<$count; $foo++)
  {
    $thisrow = $table->fetchrow_hashref();

    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"respond.pl?$thisrow->{'ID'}\">$thisrow->{'subject'}</a></font></td></tr>\n";
  }
  print "</table></td></tr></table>";

  $table->finish();
  disconnect_database($database);

  banner::bottom();
}

sub search
{
  my ($author, $text, $min, $max) = @_;
  my ($database, $count, $table, $foo, $thisrow, $imin, $imax);
  if (not defined($min)) { $min = 0; }
  if (not defined($max)) { $max = 9; }

  $database = connect_database();

  if ($ARGS{'in'} eq "responses")
  {
      $table = $database->prepare("SELECT * FROM responses WHERE (author LIKE ? AND entry LIKE ?);");
  }
  else
  {
      $table = $database->prepare("SELECT * FROM news WHERE (author LIKE ? AND entry LIKE ?);");
  }
  $table->execute("\%$author\%", "\%$text\%");
  $count = $table->rows;
  if ($count == 0) { disconnect_database($database); list("Found 0 matches"); }
  if ($max > $count) { $max = $count - 1; }
  if ($min < 0) { $min = 0; }

  require 'banner.pm';
  banner::top("archive");

  print "<table cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n";
  print "<tr valign=\"top\" bgcolor=\"#ffffff\"><td width=\"310\">\n\n";
  searchprompt($author, $text, $ARGS{'in'});

  print "</td><td width=\"1\" bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\" height=\"10\"></td><td>\n";

  tabletop(510, "Archive");
  print "<table width=\"510\" cellpadding=\"0\">";

  print "<tr><td><b>Found $count matches.  Displaying $min to $max</b></td></tr>";
  print "<tr><td>";
  if ( ($min > 0) or ($count > $max) ) { print "("; }
  if ($min > 0)
  {
    $imin = $min - 10;
    $imax = $min - 1;
    print "<a href=\"archive.pl?search=prev&author=$author&text=$text&in=$ARGS{'in'}&min=$imin&max=$imax\">prev page</a>";
  }
  if ( ($min > 0) and ($count > $max) ) { print " | "; }
  if ($count > $max)
  {
    $imin = $max + 1;
    $imax = $max + 10;
    print "<a href=\"archive.pl?search=next&author=$author&text=$text&in=$ARGS{'in'}&min=$imin&max=$imax\">next page</a>";
  }
  if ( ($min > 0) or ($count > $max) ) { print ")"; }
  print "</td></tr>";
  print "<td><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"10\" height=\"5\"></td></tr><tr><td>";
  print "<tr><td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"10\" height=\"1\"></td></tr><tr><td>";
  print "<tr><td bgcolor=\"#ffffff\"><img src=\"images/spacer.gif\" width=\"10\" height=\"5\"></td></tr><tr><td>";

  for ($foo=0; $foo<$min; $foo++) { $table->fetchrow_hashref(); }

  for ($foo=$min; $foo<=$max; $foo++)
  {
    $thisrow = $table->fetchrow_hashref();

    if ($ARGS{'in'} eq "responses")
    {
	require 'respond.pm';
      respond::show_hashref($thisrow, "yes", $thisrow->{'reference'});
    }
    else
    {
	require 'news.pm';
      news::show_hashref($thisrow);
    }
  }
  print "</td></tr></table></td></tr></table>";

  $table->finish();
  disconnect_database($database);

  banner::bottom();
}

sub searchprompt
{
  my ($a, $t, $s) = @_;

  tabletop(300, "Search");
  print "<table width=\"300\" cellpadding=\"0\"><tr><td>";
  print "<form action=\"archive.pl\" method=\"get\">";
  print "Author: <input type=\"text\" name=\"author\" value=\"$a\"><br>";
  print "Text: <input type=\"text\" name=\"text\" value=\"$t\"><br>";
  print "Search in: <input type=\"radio\" name=\"in\" value=\"news\"";
  if ($s ne "responses") { print " checked"; }
  print "> News <input type=\"radio\" name=\"in\" value=\"responses\"";
  if ($s eq "responses") { print " checked"; }
  print "> Responses<br>";
  print "<input type=\"submit\" name=\"search\" value=\"search\"><br>";
  print "</form></td></tr></table>\n";

}


main;

