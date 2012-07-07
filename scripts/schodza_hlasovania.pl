#!/usr/bin/perl
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder;
#use String::Diff;
#use Encode;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

#binmode STDOUT, ":utf8";
#binmode STDIN, ":utf8";
#use open ':encoding(utf8)';
#use open IN => ":encoding(utf8)", OUT => ":utf8";

(scalar(@ARGV) == 2) or die("Usage: $0 CISLO_SCHODZE VYSTUPNY_ADRESAR");
my $CISLO_SCHODZE = $ARGV[0];
my $OUT_DIR = $ARGV[1];

my $URL = "http://www.nrsr.sk/web/Default.aspx?sid=schodze%2fhlasovanie%2fvyhladavanie_vysledok&ZakZborID=13&CisObdobia=6&CisSchodze=$CISLO_SCHODZE&ShowCisloSchodze=False";
#my $URL = "file:///home/miso/projects/nrsr_web_parser/input.html";
#$URL = "http://nalus.usoud.cz/Search/Search.aspx";

my @rows = ();
fill_rows($URL, \@rows);
#print "all rows: ".scalar(@rows)."\n";

my @recs = ();
rows2recs(\@rows, \@recs);

mkdir "$OUT_DIR/schodza_$CISLO_SCHODZE";
my $PARLAMENTNE_TLACE_DIR = "schodza_$CISLO_SCHODZE/parlamentne_tlace";
my $PARLAMENTNE_TLACE_URL_FILENAME = $PARLAMENTNE_TLACE_DIR."_url.txt";
my $HLASOVANIA_DIR = "schodza_$CISLO_SCHODZE/hlasovania";
my $HLASOVANIA_URL_FILENAME = $HLASOVANIA_DIR."_url.txt";

#--------------------------------------------------
# MAIN
#--------------------------------------------------
uloz_zoznam_url_parlamentnych_tlaci(\@recs, "$OUT_DIR/$PARLAMENTNE_TLACE_URL_FILENAME");
uloz_zoznam_url_hlasovani(\@recs, "$OUT_DIR/$HLASOVANIA_URL_FILENAME");
system("./stiahni_parlamentne_tlace.sh '$OUT_DIR/$PARLAMENTNE_TLACE_URL_FILENAME' '$OUT_DIR/$PARLAMENTNE_TLACE_DIR'");
system("./stiahni_hlasovania.sh '$OUT_DIR/$HLASOVANIA_URL_FILENAME' '$OUT_DIR/$HLASOVANIA_DIR'");

hlasovania_to_recs(\@recs);
recs_to_html(\@recs, "schodza_$CISLO_SCHODZE.html");


#--------------------------------------------------
# FUNCTIONS
#--------------------------------------------------
sub uloz_zoznam_url_parlamentnych_tlaci()
{
	my $recs = shift;
	my $filename_out = shift;

	open(OUT, ">$filename_out") or die("ERROR: Can not open file '$filename_out' for writing!");
	my $cislo_parlamentnej_tlace_pred = -1;
	foreach my $rec (sort {$a->{cislo_parlamentnej_tlace} <=> $b->{cislo_parlamentnej_tlace}} @$recs) {
		if ($cislo_parlamentnej_tlace_pred != $rec->{cislo_parlamentnej_tlace} && $rec->{cislo_parlamentnej_tlace} ne "") {
			$cislo_parlamentnej_tlace_pred =  $rec->{cislo_parlamentnej_tlace};
			#print OUT "$rec->{cislo_parlamentnej_tlace} $rec->{parlamentna_tlac_url}\n";
			print OUT "$rec->{parlamentna_tlac_url}\n";
			#print OUT "  out=$rec->{cislo_parlamentnej_tlace}/main.htm\n";
		}
	}
	close(OUT);
}

sub uloz_zoznam_url_hlasovani()
{
	my $recs = shift;
	my $filename_out = shift;

	open(OUT, ">$filename_out") or die("ERROR: Can not open file '$filename_out' for writing!");
	foreach my $rec (@$recs) {
		my $url = $rec->{hlasovanie_podla_klubov_url};
		if ($url =~ /&ID=\d+/) {
			print OUT "$url\n";
		}
	}
	close(OUT);
}

sub recs_to_html() 
{
	my $recs = shift;
	my $out_filename = shift;

	local *STDOUT;
 	open(STDOUT, ">$OUT_DIR/$out_filename") or die("ERROR: Can not open file '$OUT_DIR/$out_filename' for writing!");
 
 	print "<html><head>\n";
#	print "<meta http-equiv='Content-Type' content='text/html; charset=latin2'/>\n";
	print "<meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>\n";
	print '<link id="_resetStylesheet" href="CSS/css_reset.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_gridStylesheet" href="CSS/grid.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_formalizeStylesheet" href="CSS/formalize.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_formsStylesheet" href="CSS/forms.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_mainPageStyleSheet" href="CSS/nrsr.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_misoPageStyleSheet" href="CSS/miso.css" type="text/css" rel="stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_jqueryUIStylesheet" href="CSS/jquery-ui-1.8.5.custom.css" type="text/css" rel="Stylesheet" media="projection, screen, tv" />'."\n";
	print '<link id="_printStylesheet" href="CSS/print.css" type="text/css" rel="stylesheet" media="print" />'."\n";
	print '</head><body><table class="tab_zoznam" cellspacing="0" cellpadding="3" border="0">'."\n";
	print "<tr class='tab_zoznam_header'>\n";
	print "  <th>datum</th>\n";
	print "  <th>CPT</th>\n";
	print "  <th>Poslanec</th>\n";
	print "  <th>Dokumenty</th>\n";
#	print "  <th>Nazov orig</th>\n";
	print "  <th>Nazov</th>\n";
	print "  <th>Hlasovanie</th>\n";
	print "</tr>\n";
	my $tr_class = "tab_zoznam_alt";
	my $cislo_parlamentnej_tlace_pred = -1;
	my $nazov_pred = "";
	foreach my $rec (sort {$a->{cislo_parlamentnej_tlace} <=> $b->{cislo_parlamentnej_tlace}} @$recs) {
#		my $je_nova_tlac = 0;
		my $je_nova_tlac = $rec->{cislo_parlamentnej_tlace} eq "";
		if ($cislo_parlamentnej_tlace_pred != $rec->{cislo_parlamentnej_tlace}) {
			$cislo_parlamentnej_tlace_pred =  $rec->{cislo_parlamentnej_tlace};
			$nazov_pred = $rec->{nazov};
			$je_nova_tlac = 1;
			print "<tr class='tab_zoznam_separator'><td colspan='5'></td></tr>";
		}
		$tr_class = ($tr_class eq "tab_zoznam_alt") ? "tab_zoznam_nonalt" : "tab_zoznam_alt";
		print "<tr class='$tr_class'>\n";
		print "  <td>$rec->{datum}<br/>$rec->{cas}</td>\n";
		if ($je_nova_tlac) {
			print "  <td><a href='$rec->{parlamentna_tlac_url}'>$rec->{cislo_parlamentnej_tlace}</a></td>\n";
			print "  <td>$rec->{meno}</td>\n";
			print "  <td>\n";
			if ($rec->{cislo_parlamentnej_tlace} ne "" && $rec->{parlamentna_tlac_url} ne "") {
				my @document_files = ();
				my $fileslist_filename = "$OUT_DIR/$PARLAMENTNE_TLACE_DIR/$rec->{cislo_parlamentnej_tlace}/list.txt";
				if (! -e $fileslist_filename) {
					print STDERR "Missing print #$rec->{cislo_parlamentnej_tlace} ...downloading\n";
					if (system("./stiahni_parlamentnu_tlac.pl '$rec->{parlamentna_tlac_url}' '$OUT_DIR/$PARLAMENTNE_TLACE_DIR'") != 0) {
						die("ERROR: Chyba pri stahovani parlamentnej tlace '$rec->{parlamentna_tlac_url}'");
					}
				}
				open(FILESLIST, $fileslist_filename) or die("ERROR: Can not open file '$fileslist_filename'\n");
				@document_files = <FILESLIST>;
				close(FILESLIST);
				#print Dumper(@document_files);
				foreach my $line (@document_files) {
					(my $filetype, my $filename, my $title) = $line =~ /^([^\s]+)\s+([^\s]+)\s+(.*)/;
					if ($filename !~ /^http/) {
						$filename = "$PARLAMENTNE_TLACE_DIR/$rec->{cislo_parlamentnej_tlace}/".basename($filename);
					}
					print "    <img src='http://www.nrsr.sk/web/img/$filetype.gif'/> <a href='$filename'>$title</a><br/>\n";
				}
			}
			print "  </td>\n";
			print "  <td>".zvyrazni_nazov_zakona($rec->{nazov})."</td>\n";
		} else {
			print "  <td></td>\n";
			print "  <td></td>\n";
			print "  <td></td>\n";
			#print "  <td>$rec->{nazov}</td>\n";
			#my $diff = my_diff(decode_utf8($nazov_pred), decode_utf8($rec->{nazov}), "diff_add");
			my $diff = my_diff($nazov_pred, $rec->{nazov});
#			if ($rec->{cislo_parlamentnej_tlace} eq "") { $nazov_pred = $rec->{nazov}; }
			print "  <td>$diff</td>\n";
#			exit;
		}
		my $td_class = 
			($rec->{hlasovanie_vysledok} eq "Návrh prešiel") ? "class='hlasovanie_navrh_presiel'" :
			($rec->{hlasovanie_vysledok} eq "Návrh neprešiel") ? "class='hlasovanie_navrh_nepresiel'" : "class='blabla'";
		print "  <td $td_class>\n";
		if ($rec->{hlasovanie_podla_klubov_url} eq "") {
			print "    tajné hlasovanie\n";
		} else {
			print "    <a href='$rec->{hlasovanie_podla_klubov_url}'>$rec->{cislo_hlasovania}</a>\n";
			if ($rec->{hlasovanie_vysledok} ne "") {
				print "    <span class='hlasovanie_za'>$rec->{hlasovanie_za}</span>\n";
				print "    <span class='hlasovanie_proti'>$rec->{hlasovanie_proti}</span>\n";
				print "    <span class='hlasovanie_zdrzalo_sa'>$rec->{hlasovanie_zdrzalo_sa}</span>\n";
				print "    <span class='hlasovanie_vysledok'>$rec->{hlasovanie_vysledok}</span>\n";
			}
		}
		print "  </td>\n";
		print "</tr>\n";
	}
	print "</table></body></html>\n";

	close(STDOUT);
}

sub zvyrazni_nazov_zakona() {
	my $str = shift;

#	print STDERR "\nzvyrazni_nazov_zakona\n";
	my $res = "";
#	while(($str =~ s/(zákon č. [\d\/]+ )(.*?)( v znení| a o doplnení)/\1<span class="nazov_highlight">\2<\/span>\3/g) > 0) {}
	while(1) {
#		print STDERR "str:$str\n";
		if (!($str =~ s/(zákon[a]? č. [\d\/]+ )([^<]*?)( v znení| a o zmene| a o doplnení)/\1<span class="nazov_highlight">\2<\/span>\3/g)) {
			last;
		}
#		print STDERR "i1:$i\n";
		(my $append, $str) = $str =~ /^(.+<\/span>)(.*)$/;
		$res = $res.$append;
	}
	return $res.$str;
}

sub my_diff() {
	my $str1 = shift;
	my $str2 = shift;

	my $span_class_name = "diff_add";
	my $res = "";

	for (my $i=0; $i<length($str2); $i++) {
		my $chr1 = substr($str1, $i, 1);
		my $chr2 = substr($str2, $i, 1);
#		print "$i: $chr1 <=> $chr2\n";
		if ($chr1 ne $chr2) {
#			print "NO MATCH\n";
			return extract_last_sentence(substr($str2, 0, $i))."<span class='$span_class_name'>".substr($str2, $i)."</span>";
		}
	}
	if (length($str1) < length($str2)) {
		return "<span class='$span_class_name'>".substr($str2, length($str1)-1)."</span>";
	}
}

sub extract_last_sentence() {
	my $str = shift;
	(my $res) = $str =~ /([^\.-]*)$/;
	return $res;
}

#rows_to_recs

#print $html;


sub rows2recs()
{
	my $rows_in = shift;
	my $recs_out = shift;
	#my $row = $rows_in[12];
	foreach my $row (@$rows_in) {
#	print "row: ".$row->content_list()->as_HTML()."\n";
		my @cells = $row->content_list();
#		print Dumper($cell);
		my %rec = ();

#		foreach my $cell (@cells) {
#			print " cell: ".$cell->as_HTML()."\n";
#		}

		# datum cas
		my @a = $cells[0]->content_list();
		$rec{datum} = $a[0]; $rec{datum} =~ s/\s+//g;
		$rec{cas}   = $a[2]; $rec{cas}   =~ s/\s+//g;

		# cislo hlasovania
		my @a = $cells[1]->content_list();
		$rec{detail_hlasovania_url} = "http://www.nrsr.sk/web/".$a[0]->attr("href");
		$rec{cislo_hlasovania} = $a[0]->as_text();
		$rec{cislo_hlasovania} =~ s/\s+//g;

		# cislo parlamentnej tlace
		my @a = $cells[2]->content_list();
		$rec{parlamentna_tlac_url} = "http://www.nrsr.sk/web/".$a[0]->attr("href");
		$rec{cislo_parlamentnej_tlace} = $a[0]->as_text();
		$rec{cislo_parlamentnej_tlace} =~ s/\s+//g;

		# nazov
		$rec{nazov} = $cells[3]->as_text();
		parse_nazov_hlasovania($rec{nazov}, \%rec);

		# hlasovanie podla klubov
		my @a = $cells[4]->content_list();
		if ($a[0]->attr("href") ne "") { # verejne / tajne hlasovanie
			$rec{hlasovanie_podla_klubov_url} = "http://www.nrsr.sk/web/".$a[0]->attr("href");
			($rec{hlasovanie_id}) = $rec{hlasovanie_podla_klubov_url} =~ /&ID=(\d+)/;
		}
		
		%{$recs_out->[scalar(@$recs_out)]} = %rec;
#		print Dumper(%rec);
#		exit;
#	$row->content()
	}
}

sub hlasovania_to_recs() {
	my $recs = shift;

	foreach my $rec (@$recs) {
		my $vysledky_hlasovania_filename = "$OUT_DIR/$HLASOVANIA_DIR/$rec->{hlasovanie_id}.txt";
		if (-e $vysledky_hlasovania_filename) {
			my $line = `cat $vysledky_hlasovania_filename`;
			chomp $line;
			(
				my $unused, 
				$rec->{hlasovanie_za}, 
				$rec->{hlasovanie_proti}, 
				$rec->{hlasovanie_zdrzalo_sa}, 
				$rec->{hlasovanie_vysledok}
			) = split(/\t/, $line);
		}
	}
}

sub parse_nazov_hlasovania() {
	my $str = shift;
	my $rec_out = shift; # reference to hash

	if ((my $meno) = $str =~ /^Návrh poslanc.{1,2} Národnej rady Slovenskej republiky (.+) na vydanie zákona/) {
#		print "meno: $meno\n";
		$rec_out->{meno} = $meno;
#		exit;
	}
}

sub fill_rows() {
	my $url = shift;
	my $rows_out = shift; # reference to array

	my $browser = WWW::Mechanize->new();
#	$browser->use_plugin('JavaScript');
	$browser->proxy('http', '');

	my $response = $browser->get($url);
	my $html = $response->as_string();

	my @pages = ();
	my $page_number = 1;
	while(1)
	{
		my $tree = HTML::TreeBuilder->new();
		$tree->parse_content($html);

		my $table = $tree->look_down("_tag", "table", sub{ $_[0]->id() =~ /_resultGrid$/ });
		#print $table->as_HTML();

		foreach my $row ($table->content_list()) {
			if ($row->attr("class") eq "pager") {
				if ($page_number == 1) {
					@pages = parse_pager_row($row);
				}
			} elsif ($row->attr("class") eq "tab_zoznam_header") {
			} else {
				push @$rows_out, $row;
#				print "row: ".$row->as_HTML()."\n";
			}
		}

		$page_number++;
		if ($page_number >= scalar(@pages)) {
			last;
		}

		$html = load_page($page_number, $browser, \@pages);
	}
}

sub load_page() {
	my $page_number = shift;
	my $browser = shift;
	my $pages = shift; # reference to array

#	print "pages count: ".scalar(@$pages)."\n";
#	print "page:$page_number f_name:".$pages->[$page_number]{name}."\n";
#	print Dumper(%{$pages->[$page_number]});
	my $f_name = $pages->[$page_number]{name};
	($f_name eq "__doPostBack") or die("ERROR: expecting function '__doPostBack', but found '$f_name' instead!\n");
	my $event_target = $pages->[$page_number]{args}[0];
	my $event_argument = $pages->[$page_number]{args}[1];
	my $response = $browser->submit_form(
		form_name => "_f",
		fields => { __EVENTTARGET => $event_target, __EVENTARGUMENT => $event_argument }
	);

	$response->is_success or die "ERROR: HTTP response: $response->status_line\n";
	return $response->as_string();
}

sub parse_pager_row() {
	my $row = shift;

	my @pages = ();
	foreach my $page ($row->look_down("_tag", "td")->content_list()) {
		if (ref($page)) {
#			print "page: $page ".$page->as_HTML()."\n";
			my $href = $page->attr("href")."\n";
			my $page_number = $page->as_text();
			my %h = split_javascript_function_call_string($href);
			%{$pages[$page_number]} = %h;
#			print "pages: ".Dumper(@pages);
		}
	}
	return @pages;
}

sub split_javascript_function_call_string() {
	my $str = shift;
	my %res = ();

	(my $f_name, my $f_args) = $str =~ /^javascript:([^\(]+)\(([^\)]+)/;
	$f_args =~ s/["']//g;
	my @a_args = split(/[,\s]+/, $f_args);
#	print "0: $a_args[0] 1:$a_args[1]\n";
#	print "f_name:$f_name f_args:$f_args\n";
	$res{name} = $f_name;
	@{$res{args}} = @a_args;
#	print "res: ".Dumper(%res)."\n";
	return %res;
}

sub basename() {
	my $path = shift;
	$path =~ s/^.*\///;
	return $path;
}
