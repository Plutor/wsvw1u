package login;
BEGIN{
  use myVacuum;
  check_cookies();
}
END{}
return 1;

sub prompt
{
    require "vbox.pm";

  if (defined($USER{'name'})) {
    vbox::head(150, "User actions");
    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"post.pl\">Post news</a></font></td></tr>";
    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"article.pl?submit\">Submit article</a></font></td></tr>";
    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"calendar.pl\">Add event</a></font></td></tr>";
    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"settings.pl\">Modify settings</a></font></td></tr>";
    print "<tr valign=\"top\"><td><font size=\"-1\">&not;</font></td><td width=\"100%\"><font size=\"-1\"><a href=\"logout.pl\"><b>Logout</b></a></font></td></tr>";


      if (user_field($USER{'name'}, "moderator") eq "Y")
      {
	  my $database = connect_database();
	  
	  my $m = $database->do("SELECT * FROM modqueue;");
	  if ($m eq "0E0") { $m = "0"; }
	  $l = $database->do("SELECT * FROM llotw WHERE(week > FLOOR((TO_DAYS( NOW() ) - TO_DAYS( '1998-10-25 00:00:00' )) / 7) );");
	  if ($l eq "0E0") { $l = "0"; }
	  $tu = $database->do("select * from users;");
	  if ($tu eq "0E0") { $tu = "0"; }
	  $au = $database->do("select * from users where (TO_DAYS(now()) - TO_DAYS(lastaccess) <= 30);");
	  if ($au eq "0E0") { $au = "0"; }
	   disconnect_database($database);

	vbox::bar();
	  print "<tr valign=\"top\"><td>&divide;</td><td width=\"100%\"><font size=\"-1\">" .
	      "<a href=\"moderate.pl\">moderate</a> </font>(<tt>$m</tt>)</td></tr>\n";
	  if ($USER{'name'} eq "log")
	  {
	      print "<tr valign=\"top\"><td>&divide;</td><td width=\"100%\"><font size=\"-1\">" .
		  "<a href=\"links.pl\">llotw</a> </font>(<tt>$l</tt>)</td></tr>\n";
	  }
	  print "<tr valign=\"top\"><td>&divide;</td><td width=\"100%\"><font size=\"-1\">" . 
	      "<a href=\"users.pl\">userlist</a> </font>(<tt>$au</tt>/<tt>$tu</tt>)</td></tr>\n";
	  print "<tr valign=\"top\"><td>&divide;</td><td width=\"100%\"><font size=\"-1\">" .
	      "<a href=\"article.pl?post\">post article</a></font></td></tr>\n";
      }
  }
  else
  {
    vbox::head(150, "Login prompt");
      vbox::row("<center><font size=\"-1\"><form action=\"login.pl\" method=\"post\">" .
		"<b>name</b><br><input type=\"text\" maxlength=\"20\" size=\"8\" name=\"name\"><br>\n" .
		"<b>passwd</b><br><input type=\"password\" maxlength=\"10\" size=\"8\" name=\"pass\"><br>\n" .
		"<input type=\"submit\" value=\"login\"> or <a href=\"create.pl\">create</a> an account" .
		"</form></font></center>");
  }

  vbox::foot();
}

