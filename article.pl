#!/usr/bin/perl

use myVacuum;
getArgs();
getArgs($ENV{'QUERY_STRING'}) if defined $ENV{'QUERY_STRING'};
    print STDERR "article.pl: test\n";

sub main
{
    if ($ENV{'QUERY_STRING'} eq "submit")
    {
	submit();
    }
    elsif ($ENV{'QUERY_STRING'} eq "post")
    {
	deny_nonmods();
	postprompt();
    }
    elsif ($ARGS{'op'} eq "Submit")
    {
	deny_nonmods();
	if ($ARGS{'title'} eq "" or
	    $ARGS{'author'} eq "" or
	    $ARGS{'intro'} eq "" or
	    $ARGS{'text'} eq "" )
	{
	    postprompt($ARGS{'author'},
		       $ARGS{'title'},
		       $ARGS{'text'},
		       $ARGS{'intro'});
	}
	else
	{   
	    post();
	}
    }
    else
    {
	view($ARGS{'article'});
    }
}

sub postprompt
{
    my ($author, $title, $text, $intro) = @_;

    require 'banner.pm';
  banner::top("article -> post");
    
    print "<center>";
    if (defined($mesg)) { print "<b>$mesg</b><br><br>"; }
    print "<form action=\"article.pl\" method=\"post\">\n";

    require 'vbox.pm';
  vbox::head(400, "Post article");
    
    vbox::row("<center>Title:<br><input type=\"text\" maxlength=\"80\" size=\"40\" name=\"title\" value=\"$title\"></center>");
    vbox::row("<center>Author (<a href=\"users.pl\">list</a>):<br><input type=\"text\" maxlength=\"40\" size=\"40\" name=\"author\" value=\"$author\"></p></center>");
    vbox::row("<center>Intro:<br><textarea wrap=\"soft\" cols=\"40\" rows=\"5\" name=\"intro\">$intro</textarea></center>");
    vbox::row("<center>Full text:<br><textarea wrap=\"soft\" cols=\"60\" rows=\"15\" name=\"text\">$text</textarea></center>");
    vbox::bar();
    vbox::row("<center><input type=\"submit\" name=\"op\" value=\"Submit\">&nbsp;<input type=\"reset\" value=\"Reset\"></center>");

  vbox::foot();
  print "</center>";
    
  banner::bottom();
    
}

sub post
{
    my $database = connect_database();

    my $post = $database->prepare("INSERT INTO articles (date, author, title, text, intro, ID) VALUES(now(), ?, ?, ?, ?, NULL);");
    $post->execute($ARGS{'author'},
		   $ARGS{'title'},
		   $ARGS{'text'},
		   $ARGS{'intro'});
    my $result = $post->rows;
    $post->finish();

    require 'banner.pm';
  banner::top("article -> post");

    if ($result == 1) { 
	print "Article successfully submitted\n";
    }
    else {
	print "Error posting article.\n";
    }

  banner::bottom();   
}

sub view
{
    my ($num) = @_;

    my $database = connect_database();

    my $table = $database->prepare("SELECT * FROM articles WHERE (ID = ?);");
    $table->execute($num);

    require 'banner.pm';
  banner::top("article -> $num");
    print "<table><tr valign=\"top\"><td rowspan=\"3\">\n";
    require 'article.pm';
  article::list();
    print "</td><td>&nbsp;</td><td class=\"just\" width=\"75%\">\n";

    if ($table->rows < 1)
    {
	print "&nbsp;No such article $num.";
    }
    else
    {
	my $art = $table->fetchrow_hashref(); 

	$art->{'author'} = yearbooklink($art->{'author'});

	$art->{'date'} = "$2 $3, $1" if ($art->{'date'} =~ /^([^-]+)-([^-]+)-([^-]+)$/);
	$art->{'date'} =~ s/^(\d+)/qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$1-1]/e;

        print "<table width=\"100%\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";
	print "<tr><td colspan=\"2\"><font size=\"+3\"><b>$art->{'title'}</b></font></td></tr>\n";
	print "<tr><td bgcolor=\"#000000\" colspan=\"2\"><img src=\"/images/spacer.gif\" width=1 height=1></td></tr>\n";
	print "<tr><td><b>by <font face=\"$sanserif\" size=\"+0\">$art->{'author'}</font></b></td><td align=\"right\">$art->{'date'}</td></tr></table>\n";
	print "$art->{'text'}";
    }
    $table->finish();

    print "</td><td width=\"100%\">&nbsp;</td></tr></table>";

  banner::bottom();
    disconnect_database($database);
}

sub submit
{
    require 'banner.pm';
  banner::top("article -> submit");
    
    print "<table width=\"500\" cellpadding=\"0\" cellspacing=\"3\"><tr><td>";

    print "<center><i></i></center>";

    print "<h2>Why is there no form here?</h2>";
    print "Submitting an article is significantly more complex than submitting a news item.  We're hoping that articles will become an important part of this web page, but we'd like them to be more thought out and organized than news items.  Thus, there is no web form for submitting an article.";

    print "<h2>What do you want in an article?</h2>";
    print "It should be coherent and intelligent, and also well-thought out.  We would really appreciate it if it were spell-checked and had decent grammar as well.  Also, if you send it in HTML, please make sure it is formatted well, and isn't in a funky font.  Anything we feel to be too garish or unviewable we will remove.";

    print "<h2>So what format do you want it in?</h2>";
    print "Straight text would probably be the easiest most of the time.  If you have images that you want within the text of your article, feel free to submit HTML.  Word, Wordpro, StarOffice docs, etc. will need to be converted before they are posted, so it may take longer before they appear.  Submitting them in text or HTML makes our job easier and makes us more likely to post your article.";

    print "<h2>Will every article be accepted?</h2>";
    print "No.  Articles that are purposely insulting or unintelligent will be rejected outright, possibly without notification of the author.  We may request that other articles with missing parts, or articles which are too long be minorly modified.  Most of the articles, however, we will post without any modifications or problems.";

    print "<h2>Where do I submit it to?</h2>";
    print "Send your article in an email to <a href=\"mailto:";
    print user_field("log", "email");
    print "\">log</a>.  Text can be placed directly in the text of the email.  Any other format should be attached.  Include a few lines with a description of the article that you'd like to appear on the home page, and also the title of the article.  Your article should show up (assuming it meets our criteria), within a couple of days.";

print "</td><td bgcolor=\"#000000\"><img src=\"images/spacer.gif\" width=\"1\"></td>";

print "</tr></table>";
  
  banner::bottom();
    
}


main;
