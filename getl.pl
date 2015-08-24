#!/usr/bin/perl -w
# Return links in an html page, and perhaps download them
# (requires wget)
#   Gets all jpg, png and mp3 files by default
# usage: getl.pl [--type|-t <filetype e.g. jpg>] [--download|-d]

use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use Getopt::Long;

my %opt = (
	type => "(jpg|png|mp3)"
);
my $url;

GetOptions(\%opt, "type|t=s", "download|d");

$url = $ARGV[0];
unless(defined($url)) {
	 die("usage: getl.pl [options] [URL]\n"
	 	."options:\n"
	 	."-t, --type      get links to files of this type, supports reg expr.\n"
	 	."-d, --download  download each file with wget\n");
}

my $agent = WWW::Mechanize->new();
$agent->get($url);

my $stream = HTML::TokeParser->new(\$agent->{content});
my $tag;
my $href;

do {
	$tag = $stream->get_tag("a");
	$href = $tag->[1]{href};

	# Convert relative link to full link
	if( defined($href) and ($href !~ /:/) ) {
		$url =~ s/[^\/]*$//g;
		$href = "$url$href";
	}

	output($href) if defined($href) and istype($href);
} while (defined($href));

sub istype {
	my $link = shift;
	return ($link =~ /$opt{type}$/);
}

sub output {
	my $link = shift;
	if (exists($opt{download})) {
		download($link);
	}
	else {
		print $link."\n";
	}
}

sub download {
	my $link = shift;
	system ("wget","--refer=$url",$link);
}
