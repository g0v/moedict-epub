#!/usr/bin/ev perl
use v5.14;
use utf8;
use EBook::EPUB;
use File::Slurp qw(read_file);
use Mojo::DOM;
use Encode qw(decode_utf8);

sub get_sym {
    my $content = decode_utf8 read_file("sym.txt");
    my %sym = split /\s/ => $content;
    return \%sym;
}

sub get_xhtml {
    state $sym = get_sym();
    my ($file, $char) = @_;
    my $content = decode_utf8 read_file($file);
    my $dom = Mojo::DOM->new("<div>$content</div>");
    $dom->find("table,tr,td")->each(
        sub {
            my $a = $_->attrs;
            for my $x (qw(border width cellspacing cellpadding)) {
                delete $a->{$x};
            }
        }
    );
    $dom->find("img")->each(
        sub {
            my $e = $_;
            my $imgfont = lc($_->attrs("src") =~ s/^images\///r =~ s/\.jpg$//r);
            my $t = $sym->{$imgfont};
            if (!$t) {
                print STDERR "MISSING: $imgfont\n";
            }
            $e->replace("<span>$t</span>");
        }
    );
    
    my $body = $dom->content_xml;
    return <<XHTML;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>$char</title>
</head>
<body>
  <h1>$char</h1>
  $body
</body>
</html>
XHTML
}

binmode STDOUT, ":encoding(utf8)";

my @chars;
for my $file (<newdict/*.html>) {
    my $char = decode_utf8($file =~ s/\.html$//r =~ s/^newdict\///r);
    push @chars, {
        char => $char,
        file => $file,
        xhtml => get_xhtml($file, $char)
    };
}

@chars = sort @chars;

my $epub = EBook::EPUB->new;
$epub->add_title('那部字典');
$epub->add_author('教育部');

for my $char (@chars) {
    my $fn_in_epub = $char->{char} . ".html";

    my $id = $epub->add_xhtml($fn_in_epub, $char->{xhtml}, linear => "yes");
    my $np = $epub->add_navpoint(
        label   => $char->{char},
        id      => $id,
        content => $fn_in_epub
    );
}

$epub->pack_zip("moedict.epub");
