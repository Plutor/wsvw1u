#!/usr/bin/perl

use myVacuum;
getArgs();

sub main
{
  if ( defined($ARGS{'name'}) and defined($ARGS{'pass'}) and defined($ARGS{'pass2'}) )
  {
    submitted($ARGS{'name'}, $ARGS{'pass'}, $ARGS{'pass2'});
  }
  else
  {
    prompt();
  }
}

sub prompt
{
  my ($mesg) = @_;
  my $c1 = "<font color=\"#007f7f\"><b>";
  my $c2 = "</b></font>";

  require 'banner.pm';
  banner::top("create");

  print "<center><form action=\"create.pl\" method=\"post\">\n";

  require 'vbox.pm';
 vbox::head(400, "Create account", "fffff0");
  if (defined($mesg)) { print "<tr><td colspan=\"2\"><center><font color=\"#ff000000\"><b>$mesg</b></font></td></tr>"; }
  print "<tr><td colspan=\"2\"><center>The data labeled with ${c1}color${c2} are required.</center></td></tr>";
  print "<tr><td align=\"right\">${c1}Handle:${c2}</td>\n" .
      "<td><input type=\"text\" maxlength=\"20\" size=\"20\" name=\"name\" value=\"$ARGS{'name'}\"></td></tr>\n";
  print "<tr><td align=\"right\">Real name:</td>" . 
      "<td><input type=\"text\" maxlength=\"80\" size=\"20\" name=\"realname\" value=\"$ARGS{'realname'}\"></td></tr>\n";
  print "<tr><td align=\"right\">${c1}Password:${c2}</td>" . 
      "<td><input type=\"password\" maxlength=\"10\" size=\"10\" name=\"pass\"></td></tr>\n";
  print "<tr><td align=\"right\">${c1}Password again:${c2}</td>" . 
      "<td><input type=\"password\" maxlength=\"10\" size=\"10\" name=\"pass2\"></td></tr>\n";
  print "<tr><td align=\"right\">Email:</td>" . 
      "<td><input type=\"text\" maxlength=\"60\" size=\"20\" name=\"email\" value=\"$ARGS{'email'}\"></td></tr>\n";
  print "<tr><td align=\"right\">Homepage name:</td>" . 
      "<td><input type=\"text\" maxlength=\"80\" size=\"20\" name=\"home_name\" value=\"$ARGS{'home_name'}\"></td></tr>\n";
  print "<tr><td align=\"right\">Homepage URL:</td>" . 
      "<td><input type=\"text\" maxlength=\"80\" size=\"20\" name=\"home_url\" value=\"$ARGS{'home_url'}\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><center>"; horizline(200); print "</center></td></tr>\n";
  if ($ARGS{'yearbooking'} eq "Y") { $c = "checked"; }
  print "<tr><td colspan=\"2\"><center><input type=\"checkbox\" name=\"yearbooking\" value=\"Y\" $c> I want others to be able to view this information in the yearbook.</td></tr>\n";
  print "<tr><td colspan=\"2\"><center>Yearbook quote:<br>\n" .
      "<input type=\"text\" maxlength=\"80\" size=\"40\" name=\"quote\" value=\"$ARGS{'quote'}\"></td></tr>\n";

  print "<tr><td colspan=\"2\"><center><input type=\"submit\" value=\"Create\"></center></td></tr>\n";

 vbox::foot();

  print "</form></center>\n\n";

  banner::bottom();
}

sub submitted
{
  my ($name, $pass, $pass2) = @_;
  my ($foo, $bar, $enc_pass) = @_;

  # make sure the passwords are the same
  if ($name eq "") { prompt("You must enter a handle"); exit; }
  if ($pass ne $pass2) { prompt("The passwords do not match"); exit; }
  if ($pass eq "") { prompt("You must enter a password"); exit; }

  my $database = connect_database(); 

  # make sure the user doesnt exist already
  $foo = $database->prepare("SELECT * FROM users WHERE (name = ?);");
  $foo->execute($name);
  if ($foo->rows != 0) { $foo->finish(); disconnect_database($database); prompt("user '$name' exists"); exit; }
  $foo->finish();

  # finally create the account
  $foo = $database->prepare("INSERT INTO users(name, password, ID, recent_news) values(?, password(?), NULL, 7);");
  $foo->execute($name, $pass);
  if ($foo->rows != 1) { $foo->finish(); disconnect_database($database); prompt("error creating user '$name'"); exit; }
  $foo->finish();

  # get the encrypted password, for the cookie
  $foo = $database->prepare("SELECT password(?)");
  $foo->execute($pass);
  $bar = $foo->fetchrow_hashref();
  for (values %{$bar}) { $enc_pass = $_; }
  $foo->finish();

  # Then update the rest of the things  
  foreach (qw(email home_url home_name realname yearbooking quote))
  {
      if ($ARGS{$_} ne "")
      {
	  $foo = $database->prepare("UPDATE users set $_=? WHERE (name=?)");
	  $foo->execute($ARGS{$_}, $name);
	  $foo->finish();
      }
  }

  disconnect_database($database); 

  # create the cookies
  print "Set-Cookie: USERNAME=$name; ";
  print "EXPIRES=Wednesday, 01-Jan-2020 12:00:00 GMT; PATH=/\n";
  print "Set-Cookie: PASSWORD=$enc_pass; ";
  print "EXPIRES=Wednesday, 01-Jan-2020 12:00:00 GMT; PATH=/\n";
  # refresh to the front page
  print "Content-type: text/html\n\n<html>\n<head>\n";
  print "<meta http-equiv=\"Refresh\" content=\"0;";
  print "URL=/\"></head><body>\n";
}




main;

