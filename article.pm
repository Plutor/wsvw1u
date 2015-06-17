package article;
BEGIN{
	use myVacuum;
}
END{}
return 1;

sub list
{
  recent(10, "no");
}

sub recent {
    my ($limit, $show_desc) = @_;
    $limit = 4 unless defined $limit;

    my $database = connect_database();

    my $rec = $database->prepare("SELECT * FROM articles ORDER BY date DESC, ID DESC LIMIT $limit");
    $rec->execute();

    require "vbox.pm";
  vbox::head(205, "Articles");
    for ($foo=0; $foo<$rec->rows; $foo++)
    {
	my $art = $rec->fetchrow_hashref();

	$art->{'author'} = yearbooklink($art->{'author'});

	if ($show_desc ne "no")
     	{
	  vbox::row("<b>$art->{'title'}</b><br>" .
		    "<b><font face=\"$sanserif\" size=\"-1\">$art->{'author'}</font></b> - $art->{'intro'}");
	  print "<tr><td align=\"right\"><font size=\"-1\"><a href=\"article.pl?article=$art->{'ID'}\">Read more</a> >></td></tr>\n";
	}
	else
	{
   	  print "<tr valign=\"top\"><td>&not;</td><td width=\"100%\"><font size=\"-1\">";
	  print "<a href=\"article.pl?article=$art->{'ID'}\"><b>$art->{'title'}</b></a>";
	  print "</font></td></tr>\n";
	}
    }
  vbox::bar();
    print "<tr><td><center><a href=\"article.pl?submit\"><font size=\"-1\">Submit..</font>" . 
	"</a></center></td></tr>\n";

  vbox::foot();
    $rec->finish();

    disconnect_database($database);
}




