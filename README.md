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

Výstup
======

Skripty generujú html a xml subory:
* schodza_CISLO.html
* schodza_CISLO.xml

Okrem toho sťahujú hlasovania a RTF dokumenty parlamentných tlačí, ktoré konvertujú do HTML formátu pre rýchlejšie prezeranie.

Priklad výstupu si môžete pozrieť tu:
* http://www.fit.vutbr.cz/~ifapso/nrsr.sk.parser/out/schodza_3.html
* http://www.fit.vutbr.cz/~ifapso/nrsr.sk.parser/out/schodza_3.xml

TODO
====

* spracovať textové prepisy vystúpení poslancov: http://www.nrsr.sk/web/Default.aspx?sid=schodze%2frozprava
* spracovať dáta z rokovaní vlády: http://www.rokovania.sk/Rokovanie.aspx

