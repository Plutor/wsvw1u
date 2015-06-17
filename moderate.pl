#!/usr/bin/perl

use myVacuum;
getArgs();

sub main
{
  deny_nonmods("moderate");

  if ( defined($ARGS{'op'}) and ($ARGS{'op'} eq "Moderate") )
  {
    submitted();
  }
  else
  {
    prompt();
  }
}

sub prompt
{
    my ($mesg) = @_;
    my ($foo, $foon);
    
    require 'banner.pm';
  banner::top("moderate");
    require 'vbox.pm';
    
    print "<center><form action=\"moderate.pl\" method=\"post\">\n";
    
    if (defined($mesg) and $mesg ne "")
    {
	print "<p><font color=\"#ff0000\"><b>$mesg</b></font></p>\n";
    }

    my $db = connect_database(); 
    my $table = $db->prepare("SELECT * FROM modqueue ORDER BY ID;");
    $table->execute();
    if ($table->rows > 0)
    {
	require 'news.pm';
	
	for ($foo=1; $foo<=$table->rows; $foo++)
	{
	    my $thisrow = $table->fetchrow_hashref();
	    #$time = $thisrow->{'time'};
	    #$entry = $thisrow->{'entry'};
	    #$entry =~ s/\r/<br>/g;
	    #$author = $thisrow->{'author'};
	    #$subject = $thisrow->{'subject'};
	    $id = $thisrow->{ID};
	    
	  vbox::head(500, "Pre-moderated post $id", "ffffff");
	    print "<tr><td>";
	  #news::show($time, $author, $subject, $entry, "", 0, "last");
	  news::show_hashref($thisrow, "last");
	    print "</td></tr>";
	    #if ($id < 10) { $foon = "0". $id; } else { $foon = $id; }
	    $foon = $id;
	    
	  vbox::bar("cfcfcf");
	  vbox::row("<center><input type=\"radio\" name=\"$foon\" value=\"i\" checked> Ignore " .
		    "<input type=\"radio\" name=\"$foon\" value=\"r\"> Reject " .
		    "<input type=\"radio\" name=\"$foon\" value=\"a\"> Accept</center>");
	    
	  vbox::foot();
	}
	
      vbox::head(400, "Verification", "cfcfcf");
	print "<tr><td align=\"right\"><b>$USER{'name'}</b>'s password:</td>" .
	    "<td><input type=\"password\" name=\"password\" width=\"10\" maxlength=\"10\"></td></tr>\n";
	print "<tr><td colspan=\"2\"><center><input type=\"submit\" value=\"Moderate\" name=\"op\"> " .
	    "<input type=\"reset\" value=\"Reset\"></center></td></tr>";
      vbox::foot();
	print "</form></center>";
    }
    else {
	print "<p>There is no news to moderate.  Go <a href=\"\">away</a>.</p>";
    } 
    
    $table->finish();
    disconnect_database($db);
    
  banner::bottom();
}

sub submitted
{
    my ($gp) = check_password($USER{'name'}, $ARGS{'password'}, "plain");
    if ( not $gp )
    {
	prompt("Incorrect password");
	exit;
    }
    
    require 'banner.pm';
  banner::top("moderate -> done", "2;URL=index.pl");
    my $db = connect_database(); 
    
    for my $foo (sort {$a <=> $b} keys %ARGS)
    {
	if ($foo eq "op" or $foo eq "password") { next; }
	
	my $select = $db->prepare("SELECT * FROM modqueue WHERE (ID = ?)");
	$select->execute($foo);
	if ($select->rows == 0)
	{
	    print "$foo -> r_error<br>";
	    $select->finish();
	    next;
	}
	my $thisrow = $select->fetchrow_hashref();
	
	if ($ARGS{$foo} eq "a")
	{
	    my $res = $db->prepare("INSERT INTO news(time, author, subject, ID, entry, isevent) VALUES(?, ?, ?, NULL, ?, ?);");
	    $res->execute($thisrow->{'time'}, $thisrow->{'author'}, $thisrow->{'subject'}, $thisrow->{'entry'}, $thisrow->{isevent});
	    $count = $res->rows;
	    $res->finish();
	    my $del = $db->prepare("DELETE FROM modqueue WHERE (ID = ?)");
	    $del->execute($foo);
	    $del->finish();
	}
	elsif ($ARGS{$foo} eq "r")
	{
	    #my $res = $db->prepare("INSERT INTO rejects(time, author, subject, ID, entry) VALUES(?, ?, ?, NULL, ?);");
	    #$res->execute($thisrow->{'time'}, $thisrow->{'author'}, $thisrow->{'subject'}, $thisrow->{'entry'});
	    #$count = $res->rows;
	    #$res->finish();
	    $count=1;
	    
	    my $del = $db->prepare("DELETE FROM modqueue WHERE (ID = ?)");
	    $del->execute($foo);
	    $del->finish();
	}
		
	if ($ARGS{$foo} eq "i")
	{
	    print "$foo -> ignore<br>";
	}
	elsif ($count == 0)
	{
	    print "$foo -> w_error<br>";
	}
	else
	{
	    print "$foo -> $ARGS{$foo}<br>";
	}
	$select->finish();
    }
    disconnect_database($db);

  banner::bottom;
}



main;

