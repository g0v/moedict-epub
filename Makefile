
epub : moedict.epub
	perl to-epub.pl

deps :
	cpanm Unicode::Collate Mojo JSON Mojo EBook::EPUB EBook::EPUB::Lite
