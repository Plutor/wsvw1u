#!/usr/bin/perl

use myVacuum;

require 'banner.pm';
banner::top("help");

print "<table width=\"500\" cellpadding=\"0\" cellspacing=\"3\"><tr><td>";

print "<center><i>Hopefully you don't really need much help, because this page is far from complete..</i></center>";

print "<h2>Why can't I post news or responses?</h2>";
print "You need to be a member to do either of those things.  Hopefully there is a link that says \"<a href=\"create.pl\">Create account</a>\" on the top of the home page that will allow you to create an account.  You need Javascript to be able to do this correctly, and actually I would recommend a browser that likes CSS1 also.";

print "<h2>I'm a member but I still can't do it!</h2>";
print "Well, you may need to log in.  Click on \"<a href=\"login.pl\">login</a>\" on the top of the home page.  my.Vacuum stores a 'cookie' on your computer so that every time you visit wsvw1u.com, the computer knows who you are (Yes I know it's very insecure, and no i don't care).  If you login and you still can't post, wing me an email.. there may be a bug..";

print "<h2>Wait a minute.. couldn't people do stuff as me then?</h2>";
print "Yes they would, if I hadn't provided a <a href=\"logout.pl\">logout</a> option.  I'm not that stupid.";

print "<h2>How do i get listed in the yearbook?  How come some people have their yearbook entry as a link from their names?</h2>";
print "You need to set some things in the \"<a href=\"settings.pl\">settings</a>\" for this.  When you activate yearbooking, you will need to <a href=\"mailto:", user_field('log', 'email'), "\">email</a> me a picture for it to appear.  Also, if you haven't accessed your account in the past 30 days, your yearbook entry will vanish (just logging in will make it reappear, however).";

print "<p><center><i>I'll add more stuff as it occurs to me.  Feel free to <a href=\"mailto:", user_field('log', 'email'), "\">email</a> me if you have any problems and I may add it to this page..</i></center>";

print "</td><td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\"></td>";

print "</tr></table>";

banner::bottom();

