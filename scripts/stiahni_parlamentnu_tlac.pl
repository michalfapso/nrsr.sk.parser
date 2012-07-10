#!/usr/bin/perl
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Data::Dumper;

if (scalar(@ARGV) != 2) {
	print STDERR "Usage: $0 URL DOWNLOAD_DIR\n";
	exit 1;
}

$Data::Dumper::Maxdepth = 2;
#my $URL = "http://www.nrsr.sk/web/Default.aspx?sid=zakony/cpt&ZakZborID=13&CisObdobia=6&ID=102";
#my $DOWNLOAD_DIR = "./parlamentne_tlace";
my $URL = $ARGV[0];
my $DOWNLOAD_DIR = $ARGV[1];
(my $CISLO_TLACE) = $URL =~ /&ID=(\d+)/;
if ($CISLO_TLACE eq "") { die("ERROR: Invalid URL '$URL'!"); }

if (-e "$DOWNLOAD_DIR/$CISLO_TLACE/list.txt") {
	print STDERR "parlamentna tlac $CISLO_TLACE je uz stiahnuta ...nestahujem\n";
	exit;
}

mkdir $DOWNLOAD_DIR;
$DOWNLOAD_DIR .= "/$CISLO_TLACE";
mkdir $DOWNLOAD_DIR;

my $browser = WWW::Mechanize->new();
#	$browser->use_plugin('JavaScript');
$browser->proxy('http', '');

my $response = $browser->get($URL);
my $html = $response->as_string();

my $tree = HTML::TreeBuilder->new();
$tree->parse_content($html);

my $div = $tree->look_down("_tag", "div", sub{ $_[0]->attr("class") eq "parliamentary_press_details" });
my @a = $div->content_list();

#print Dumper(@a);
my @b = $a[4]->look_down("_tag", "span")->content_list();
#print Dumper(@b);

my $fileslist_contents = "";
my $filetype = "";
foreach my $e (@b) {
	if (ref($e)) {
		if ($e->tag() eq "img") {
			($filetype) = $e->attr("src") =~ /\/(...)\.gif$/i;
			$filetype = lc($filetype);
		} elsif ($e->tag() eq "a") {
			my $name = $e->as_text();
			$name =~ s/\s\(.*\)//;
#			print "$filetype: ".$e->attr("href")." ".$name."\n";

			my $file_url = $e->attr("href");
			if ($filetype eq "rtf") {
				my $output_filename = download_document($e->attr("href"), "$DOWNLOAD_DIR");
				$file_url = rtf_to_html($output_filename);
				($filetype) = $file_url =~ /([^\.]+)$/;
			}
			$fileslist_contents .= "$filetype\t$file_url\t$name\n";
		}
#		print "e: ".$e->as_HTML()."\n";
	}
}

#print "fileslist_contents: $fileslist_contents\n";
open(FILESLIST, ">$DOWNLOAD_DIR/list.txt") or die("ERROR: Can not open file '$DOWNLOAD_DIR/list.txt'");
print FILESLIST $fileslist_contents;
close(FILESLIST);

sub download_document() {
	my $url = shift;
	my $download_dir = shift;

	my $response = $browser->get($url);
	my $output_filename = "$download_dir/".$response->filename;
#	print "response filename: $output_filename\n";
	open(OUT, ">$output_filename") or die("ERROR: Can not open file '$output_filename' for writing!");
	binmode(OUT);
	print OUT $response->content();
	close(OUT);
	return $output_filename;
#	system("wget --content-disposition --directory-prefix=$download_dir --no-proxy --no-check-certificate -U 'Mozilla/5.0 (X11; U; Linux i686 (x86_64); en-GB; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1' $url");
}

#rtf_to_html("tlac_0102-dovodova.rtf", "tlac_0102-dovodova.html");

sub rtf_to_html() {
	my $rtf_filename_in = shift;
	my $html_filename_out = $rtf_filename_in;
	$html_filename_out =~ s/\.[^\.]+$/.htm/; 
	if (system("rtf2html $rtf_filename_in $html_filename_out.x && cat $html_filename_out.x | iconv -f cp1250 -t utf8 | sed 's/<head>/<head><meta http-equiv=\"Content-Type\" content=\"text\\/html; charset=utf-8\"\\/>/' > $html_filename_out && rm $html_filename_out.x && mv $rtf_filename_in $rtf_filename_in.bak") != 0) {
		print STDERR "ERROR: rtf2html $rtf_filename_in\n";
		return basename($rtf_filename_in);
	}
	return basename($html_filename_out);
}

sub basename() {
	my $path = shift;
	$path =~ s/^.*\///;
	return $path;
}
