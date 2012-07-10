#!/usr/bin/perl
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Data::Dumper;
use threads;

if (scalar(@ARGV) != 2) {
	print STDERR "Usage: $0 URL DOWNLOAD_DIR\n";
	exit 1;
}

$Data::Dumper::Maxdepth = 2;
#my $URL = "http://www.nrsr.sk/web/Default.aspx?sid=zakony/cpt&ZakZborID=13&CisObdobia=6&ID=102";
#my $DOWNLOAD_DIR = "./parlamentne_tlace";
my $URL = $ARGV[0];
my $DOWNLOAD_DIR = $ARGV[1];
(my $ID_HLASOVANIA) = $URL =~ /&ID=(\d+)/;
if ($ID_HLASOVANIA eq "") { die("ERROR: Invalid URL '$URL'!"); }

if (-e "$DOWNLOAD_DIR/$ID_HLASOVANIA.txt") {
	print STDERR "hlasovanie #$ID_HLASOVANIA je uz stiahnute ...nestahujem\n";
	exit;
}

mkdir $DOWNLOAD_DIR;

my $browser = WWW::Mechanize->new();
#	$browser->use_plugin('JavaScript');
$browser->proxy('http', '');

my $response = $browser->get($URL);
my $html = $response->as_string();

my $tree = HTML::TreeBuilder->new();
$tree->parse_content($html);

my $div = $tree->look_down("_tag", "div", sub{ $_[0]->attr("id") =~ /_votingResultCell$/ })->look_down("_tag", "span");
my $vysledok_hlasovania = $div->as_text();

my $div = $tree->look_down("_tag", "div", sub{ $_[0]->attr("class") eq "voting_stats_summary_full" && scalar($_[0]->content_list()) > 6 });
my @a = $div->content_list();
my $za         = $a[2]->look_down("_tag", "span")->as_text();
my $proti      = $a[3]->look_down("_tag", "span")->as_text();
my $zdrzalo_sa = $a[4]->look_down("_tag", "span")->as_text();
#print "za:$za proti:$proti zdrzalo_sa:$zdrzalo_sa\n";

open(OUT, ">$DOWNLOAD_DIR/$ID_HLASOVANIA.txt") or die("ERROR: Can not open file '$DOWNLOAD_DIR/$ID_HLASOVANIA.txt'");
print OUT "$ID_HLASOVANIA\t$za\t$proti\t$zdrzalo_sa\t$vysledok_hlasovania\n";
close(OUT);
