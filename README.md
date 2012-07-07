nrsr.sk.parser
==============

<i>English info: scripts for processing data from www.nrsr.sk</i>

Skripty na sťahovanie dát a ich spracovanie z portálu www.nrsr.sk

Požiadavky
==========

* linux
* perl s modulmi WWW::Mechanize, HTML::TreeBuilder, Data::Dumper (for debugging)
* gnu parallel (http://www.gnu.org/software/parallel/)
* rtf2html (http://www.sourceforge.net/projects/rtf2html)

Použitie
========

	cd scripts
	mkdir ../out
	./schodza_hlasovania.pl 3 ../out
