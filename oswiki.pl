#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
#disabled strict because of var as filehandle
#use strict; 
use warnings;
print "Content-type: text/html\n\n\n";


my $query = new CGI;
main($query);





################################################################################
# CONFIGURATION
################################################################################



################################################################################
# MAIN LOOP
################################################################################

sub main($query)
{

	##what shall we do?

	$query->param("command","parse") unless defined $query->param("command");
	$query->param("page","wiki") unless defined $query->param("page");
#	$query->param("page","wiki") if $query->param("page") eq  "oswiki.pl";

	if($query->param("command") eq "edit")
	{
		edit();
	}
	elsif ($query->param("command") eq "show")
	{
		show();
	}
	elsif($query->param("command") eq "update")
	{
		update();
	}
	elsif($query->param("command") eq "parse")
	{
		parse();
	}
	else
	{
		create();
	}
}


sub show()
{
	open(FILE,$query->param("page"))
	or die "Fehler beim Öffnen der Datei: $!\n";
	while(defined(my $line = <FILE>))
	{
		print $line;
	}
	close(FILE); 	
	my $filename = $query->param("page");
	print "<a href=\"oswiki.pl?command=edit&page=$filename\">edit</a>";
	print "<a href=\"oswiki.pl?command=create&page=$filename\">create</a>";
}

sub edit()
{
	
	my $filename = $query->param("page");
	print '<form action="oswiki.pl" method="post" >';
	print '<input type="hidden" name="command" value="update">';
	print "<input type=\"hidden\" name=\"page\" value=\"$filename\">";
	print '<textarea cols="100" rows="30" name="source">';
	open(FILE,$query->param("page"))
	or die "Fehler beim Öffnen der Datei: $!\n";
	while(defined(my $line = <FILE>))
	{
		print $line;
	}
	close(FILE); 	
	print '</textarea>';
	print '<input type="submit" name="Ok" value="Speichern">';
	print '</form>';



}

sub update()
{
	my $filename = $query->param("page");
	open(FILE," > $filename ")
	or die "Fehler beim Öffnen der Datei: $!\n";
	print FILE $query->param("source");
	close FILE;
	parse();


}

sub create
{
	my ($filename) = @_;
	
	print '<form action="oswiki.pl" method="post" >';
	print '<input type="hidden" name="command" value="update">';
	if(defined $filename)
	{
		print "page title: <input type=\"text\" name=\"page\" value=\"$filename\" > "; 
	}
	else
	{	
		print 'page title: <input type="text" name="page" > '; 
	}
	print '<textarea cols="100" rows="30" name="source">';
	print '</textarea>';
	print '<input type="submit" name="Ok" value="Speichern">';
	print '</form>';



}

sub parse
{
	print parse_file($query->param("page"));
	$filename = $query->param("page");
	print "<hr />";	
	print "<a href=\"oswiki.pl?command=edit&page=$filename\">edit</a> &nbsp;";
	print "<a href=\"oswiki.pl?command=create&page=$filename\">create</a>";
}

sub parse_file
{

	my %parse_map = (
				"<%ilink .* %>" => "parse_ilink",
				"<%link .* %>" => "parse_ilink"
			); 

	my ($page) = @_;
	my $filename;
	my $return_string;
	if($page)
	{
		$filename = $page;
	}
	else
	{
		$filename = $query->param("page");
	}

	if (! open($filename,"$filename"))
	{
		create($filename);
	} 
	while( my $line = <$filename>)
	{
		#replace \n with \n<br />
		$line =~ s/\n/\n<br \/>/;
		if( $line =~ m/<%include (.*)%>/)
		{
			$file = $1;
			$content = parse_file($file);
			$line =~ s/<%include .* %>/$content/;
			$return_string.= $line;
		}
		elsif( $line =~ m/<%include_noparse (.*)%>/)
		{	$fn = $1;
			$x = open($fh,$fn);
			while( my $content_line = <$fh>)
			{
				$content.= $content_line;
			}
			$line =~ s/<%include_noparse .* %>/$content/;
			$return_string.= $line;
		}
		elsif($line =~ m/<%link (http.*) (.*) %>/)
		{
			$add = $1;
			$text = $2;	
			$line =~ s/<%link .* .* %>/<a href="$add">$text<\/a>/;
			$return_string .=  $line;								
		}
		elsif($line =~ m/<%ilink (.*?) (.*) %>/)
		{
			$add = $1;
			$text = $2;	
			$line =~ s/<%ilink .* %>/<a href="\/oswiki\.pl?\/command=parse&page=$add">$text<\/a>/;
			$return_string.= $line;
		}
		else 
		{$return_string.= $line;}
	}
	close $filename;
	#show();
	return $return_string;


}


