#!/usr/bin/perl

use myVacuum;
getArgs();

sub main
{
  if (defined($ARGS{'name'}) and defined($ARGS{'pass'}))
  {
    submitted($ARGS{'name'}, $ARGS{'pass'});
  }
  elsif (defined($ARGS{'op'}) and $ARGS{'op'} eq "Reset password")
  {
    resetpass($ARGS{'name'});
  }
  elsif ($ENV{'QUERY_STRING'} =~ /^forgot=(.*)$/)
  {
    forgotpass($1);
  }
  else
  {
    prompt(undef, $ENV{'QUERY_STRING'});
  }
}

sub prompt
{
    my ($mesg, $fwd) = @_;
    
    require 'banner.pm';
  banner::top("login");
    
    require 'vbox.pm';
    print "<form action=\"login.pl\" method=\"post\">\n";

    if (defined $mesg)
    {
      print "<center>$W1$mesg$W2";
      if ($mesg eq "Access denied")
      {
        print "<br>";
        print "Dont have an account?  <a href=\"create.pl\">Create one.</a><br>\n";
        print "Forgot your password?  <a href=\"login.pl?forgot=$ARGS{'name'}\">Get it.</a>\n";
      }
      print "</center>";
    }

  vbox::head(250, "Login");
    print "<tr><td align=\"right\">Name:</td>" .
	"<td><input type=\"text\" maxlength=\"20\" size=\"20\" name=\"name\" value=\"$ARGS{'name'}\"></td></tr>\n";
    print "<tr><td align=\"right\">Password:</td>" .
	"<td><input type=\"password\" maxlength=\"10\" size=\"10\" name=\"pass\"></td></tr>\n";
    print "<tr><td colspan=\"2\"><center><input type=\"submit\" value=\"submit\"></center></td></tr>\n";
    
  vbox::foot();
    print "<input type=\"hidden\" name=\"fwd\" value=\"$fwd\"></form>";

  banner::bottom();
}

sub submitted
{
  my ($name, $pass) = @_;

  my $fwd = $ARGS{'fwd'} || "index.pl";
  my ($access, $enc_pass) = check_password($name, $pass, "plain");

  if ($access == 0) { prompt("Access denied", $fwd); }
  elsif ($access == 1)
  {
    # create the cookies
    print "Set-Cookie: USERNAME=$name; ";
    print "EXPIRES=Wednesday, 01-Jan-2020 12:00:00 GMT; PATH=/\n";
    print "Set-Cookie: PASSWORD=$enc_pass; ";
    print "EXPIRES=Wednesday, 01-Jan-2020 12:00:00 GMT; PATH=/\n";
    # refresh to the front page
    print "Content-type: text/html\n\n<html>\n<head>\n";
    print "<meta http-equiv=\"Pragma\" content=\"no-cache\">\n";
    print "<meta http-equiv=\"Refresh\" content=\"0;";
    print "URL=$fwd\"></head><body>\n";
  }
  else { print "error: something bad!"; }
}

sub forgotpass
{
  my ($name) = $1;

  require 'banner.pm';
  require 'vbox.pm';
  banner::top("login -> password");

  my $db = connect_database();
  $s = $db->prepare("SELECT * FROM users WHERE (name=?);");
  $s->execute($name);

  if ($s->rows != 1)
  {
    vbox::head(400, "Error");
    vbox::row("<center>User <b>$name</b> does not exist</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }
  
  my $u = $s->fetchrow_hashref();

  if ($u->{'email'} !~ /\@/)
  {
    vbox::head(400, "Error");
    vbox::row("<center>User <b>$name</b> does not have an email address in its profile.  In order to get your password, you should email <a href=\"mailto:log\@wsvw1u.com\">log</a>.</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }

  my $email = $u->{'email'};
  vbox::head(400, "You forgot your password");
  vbox::row("<center>By clicking below, the password for <b>$name</b> will be set to a random string of characters.  An email will be sent to <b>$email</b>, the email account set in the profile.  <i>If you will not be able to get this email, do not click.  Send an email to <a href=\"mailto:log\@wsvw1u.com\">log</a>.</i></center>");
  vbox::bar();
  vbox::row("<form action=\"login.pl\" method=\"post\"><center><input type=\"hidden\" name=\"name\" value=\"$name\"><input type=\"submit\" name=\"op\" value=\"Reset password\"></center></form>");
  vbox::foot();

  $s->finish();

  banner::bottom();
}

sub resetpass
{
  my ($name) = @_;

  require 'vbox.pm';
  require 'banner.pm';
  banner::top();

  my $db = connect_database();
  $s = $db->prepare("SELECT * FROM users WHERE (name=?);");
  $s->execute($name);

  if ($s->rows != 1)
  {
    vbox::head(400, "Error");
    vbox::row("<center>User <b>$name</b> does not exist</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }
 
  my $u = $s->fetchrow_hashref();

  if ($u->{'email'} !~ /\@/)
  {
    vbox::head(400, "Error");
    vbox::row("<center>User <b>$name</b> does not have an email address in its pr
ofile.  In order to get your password, you should email <a href=\"mailto:log\@wsv
w1u.com\">log</a>.</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }

  my $email = $u->{'email'};
  $s->finish();

  # generate a random password
  srand(time ^ $$);
  my @chars = (a..z,0..9);
  my $newpass = undef;
  for (my $i=0; $i<8; $i++) { $newpass .= $chars[rand(@chars)]; }

  $s = $db->prepare("UPDATE users SET password=password(?) WHERE (name=?);");
  $s->execute($newpass, $name);

  if ($s->rows != 1)
  {
    vbox::head(400, "Error");
    vbox::row("<center>There was an error changing the password for <b>$name</b>.</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }
  $s->finish();

  if (not open(MAIL, "|mail $email"))
  {
    vbox::head(400, "Error");
    vbox::row("<center>There was an error opening <tt>/bin/mail</tt>.</center>");
    vbox::foot();
    banner::bottom();
    exit;
  }
  print MAIL "From: \"wsvw1u.com Administrator\" <root>\nTo: $email\nSubject: Password reset\n\nThe password for your account on wsvw1u.com has been automatically reset using the online form.  Either you did this yourself, or someone has been fooling around.\n\nThe new settings are:\n  Username: $name\n  Password: $newpass\n";
  close(MAIL);

  vbox::head(400, "Password reset");
  vbox::row("<center>Your password has been reset.  You should receive an email soon containing the password.  If you do not, email <a href=\"mailto:log\@wsvw1u.com\">log</a>.</center>");
  vbox::foot();
  banner::bottom();
}


main;

