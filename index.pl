#!/usr/bin/perl

use myVacuum;

require 'banner.pm';
banner::top();

print "<br>\n";
print "<table cellspacing=\"3\" cellpadding=\"0\" border=\"0\">\n";
print "<tr valign=\"top\" bgcolor=\"#ffffff\"><td width=\"210\">\n\n";

require 'calendar.pm';
calendar::upcoming();

require 'article.pm';
article::recent();

print "</td><td width=\"100%\">";

require 'news.pm';
news::recent();

print "</td>";
print "<td width=\"150\">";

require 'login.pm';
login::prompt();

require 'facebox.pm';
facebox::facebox();

news::older();

require 'llotw.pm';
llotw::this();

print "</td></tr></table>";

banner::bottom();





