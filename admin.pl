#!/usr/bin/perl

use myVacuum;
deny_nonmods();

require 'banner.pm';
banner::top("admin");

my $database = connect_database();

my $count = $database->do("SELECT * FROM modqueue;");
if ($count eq "0E0") { $count = "0"; }
print "<ul><li><p><a href=\"moderate.pl\">moderate</a> ($count items waiting)</p></li>";

$count = $database->do("SELECT * FROM llotw WHERE(week > FLOOR((TO_DAYS( NOW() ) - TO_DAYS( '1998-10-25 00:00:00' )) / 7) );");
if ($count eq "0E0") { $count = "0"; }
print "<li><p><a href=\"links.pl\">log's link of the week</a> ($count future links)</p></li>";

print "<li><p><a href=\"users.pl\">userlist</a> (";
$count = $database->do("select * from users;");
if ($count eq "0E0") { $count = "0"; }
print "$count users, ";
$count = $database->do("select * from users where (TO_DAYS(now()) - TO_DAYS(lastaccess) <= 30);");
if ($count eq "0E0") { $count = "0"; }
print "$count active)</p></li>";

print "<li><p><a href=\"article.pl?post\">post article</a></p></li>";

print "</ul>";

disconnect_database($database);
banner::bottom();

