
epub : moedict.epub
	perl to-epub.pl

deps :
	cpanm Unicode::Properties Unicode::Collate Mojo JSON Mojo EBook::EPUB
