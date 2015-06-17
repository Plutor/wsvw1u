package facebox;
BEGIN{
  use myVacuum;

  @FACES = ( akanah00, blanco98, dave96, dave99, george00, hobbes99,
             kebor99, khatt00, khatt98, matt98, nomad98, occstr99,
             pixie98, sean00, splatta99, strider99, tradr00, yurei98 );
}
END{}
return 1;

sub facebox
{
    srand ($$ ^ time);
    my $pic = $FACES[rand(@FACES)];

    require 'vbox.pm';
  vbox::head_nocp(150, "Faces of NVAD");
  vbox::row("<a href=\"faces.pl\"><img src=\"/images/faces/$pic.jpg\" border=\"0\" width=\"146\"></a>");
  vbox::foot();
}

sub faceindex
{
    for my $face (@FACES)
    {
	$face =~ /^(\D+)(\d+)$/;
	my $name = $1;
	my $year = $2;

	$fa{$name}{$year} = $face;
	$years{$year} = 1;
	$names{$name} = 1;
    }

    print "<center>\n";
    print "<table border=0 cellpadding=0 cellspacing=3>\n";
    print "<tr><td></td>";
    for my $y (sort {if ($a<96 and $b>=96) {return $a+100 <=> $b;}
		     if ($b<96 and $a>=96) {return $a <=> $b+100;}
		     else {return $a <=> $b;}} keys %years)
    {
	print "<td><center><b>NVAD$y</b></center></td>";
    }
    print "</tr>\n";

    for my $n (sort keys %names)
    {
	print "<tr><td align=\"right\"><b>$n</b></td>\n";
	for my $y (sort {if ($a<96 and $b>=96) {return $a+100 <=> $b;}
			 if ($b<96 and $a>=96) {return $a <=> $b+100;}
			 else {return $a <=> $b;}} keys %years)
	{
	    if (defined $fa{$n}{$y})
	    {
		print " <td>";
		print "<img src=\"/images/faces/$fa{$n}{$y}.jpg\">";
		print "</td>\n";
	    }
	    else
	    {
		print " <td bgcolor=\"#cfcfcf\"><center>",
		"<font color=\"#9f9f9f\">None</font></center></td>\n";
	    }
	}
	print "</tr>\n";
    }
    print "</table></center>\n";
}
