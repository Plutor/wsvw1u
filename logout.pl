#!/usr/bin/perl

# create old cookies
print "Set-Cookie: USERNAME=foo; ";
print "EXPIRES=Tuesday, 01-Jan-1980 12:00:00 GMT; PATH=/\n";
print "Set-Cookie: PASSWORD=bar; ";
print "EXPIRES=Tuesday, 01-Jan-1980 12:00:00 GMT; PATH=/\n";
# refresh to front page
print "Content-type: text/html\n\n<html>\n<head>\n";
print "<meta http-equiv=\"Pragma\" content=\"no-cache\">\n";
print "<meta http-equiv=\"Refresh\" content=\"0;";
print "URL=index.pl\"></head></html>\n";

