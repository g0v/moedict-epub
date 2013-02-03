#!/usr/bin/ev perl
use v5.14;
use utf8;
use encoding 'utf8';
use EBook::EPUB;
use File::Slurp qw(read_file);
use Mojo::DOM;
use Encode qw(decode_utf8);
use Unicode::Properties qw(uniprops);
use Unicode::Collate;
use Unicode::Collate::CJK::Stroke;
use DBI;
use Mojo::Template;

sub mt { state $mt = Mojo::Template->new }

sub sort_by_cjk_strokes {
    state $sorter = Unicode::Collate->new(overrideCJK => \&Unicode::Collate::CJK::Stroke::weightStroke);
    return $sorter->sort(@_);
}

sub dbh_moedict() {
    state $dbh = DBI->connect("dbi:SQLite:dbname=moedict.sqlite3", "", "", { sqlite_unicode => 1 });
}

sub radicals {
    state @radicals;
    return @radicals if @radicals;

    ## Some character entries has no radicals
    # sqlite> SELECT title FROM entries WHERE length(title) = 1 AND radical is NULL;
    # 鸔
    # 攵
    # 灃
    # 湼
    # 簆
    # ⼅
    # ⼛

    @radicals = @{ dbh_moedict->selectcol_arrayref("SELECT DISTINCT radical FROM entries WHERE length(title) = 1 AND radical IS NOT NULL") };

    if (grep { !$_ } @radicals) {
        warn "Warning: the list of radicals contains falsy value\n";
    }

    @radicals = sort_by_cjk_strokes @radicals;
    return @radicals;
}

sub chars_with_radical {
    my $radical = shift;
    my $chars = dbh_moedict->selectcol_arrayref("SELECT title FROM entries WHERE radical = ?", {}, $radical);

    ## Exclude entries with <img> tags, basically means missig mappings in sym.txt
    @$chars = sort_by_cjk_strokes grep { !/</ } @$chars;

    return @$chars;
}

sub definitions_of_heteronym {
    my $heteronym_id = shift;
    my $def = dbh_moedict->selectall_arrayref("SELECT type, def FROM definitions WHERE heteronym_id = ?", { Slice => {} }, $heteronym_id);
    return $def;
}

sub heteronyms_of_character {
    my $character = shift;
    my ($entry_id) = @{dbh_moedict->selectcol_arrayref("SELECT id FROM entries WHERE title = ?", {}, $character)};
    my $heteronyms = dbh_moedict->selectall_arrayref("SELECT id,bopomofo,bopomofo2,pinyin FROM heteronyms WHERE entry_id = ?", { Slice => {} }, $entry_id);

    for (@$heteronyms) {
        $_->{definitions} = definitions_of_heteronym( $_->{id} );
    }

    return $heteronyms
}

sub template_chapter() {
#   <style>body { margin-left: 5%; margin-right: 5%; margin-top: 5%; margin-bottom: 5%; text-align: justify; -epub-writing-mode: vertical-rl;}</style>

    return <<'TEMPLATE';
% my ($title, $content) = @_;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title><%= $title %></title>
</head>
<body>
  <%= $title %>
  <%= $content %>
</body>
</html>
TEMPLATE
}

sub template_character {
    return <<'TEMPLATE';
% my ($character, $heteronyms) = @_;
% for my $h (@$heteronyms) {
<h3><%= $character %><%= $h->{bopomofo} %></h3>
<dd>
    <dl>
%   for my $d (@{$h->{definitions}}) {
        <dt><%= $d->{type} %></dt>
        <dd><%= $d->{def} %></dd>
%   }
    </dl>
</dd>
% }
TEMPLATE
}


sub build_chapter {
    my ($radical, @characters) = @_;
    my $title = "$radical 部";
    my $content = "";

    for my $c (@characters) {
        my $h = heteronyms_of_character($c);
        $content .= mt->render(template_character, $c, $h);
    }

    my $content = mt->render(template_chapter, $title, $content);

    return {
        title => $title,
        content => $content
    }
}

sub build_epub {
    my @chapters;

    for my $radical (sort_by_cjk_strokes radicals) {
        push @chapters, build_chapter $radical => chars_with_radical $radical;
    }

    my $epub = EBook::EPUB->new;
    $epub->add_title('萌典');
    $epub->add_author('3du.tw');

    for my $ch (@chapters) {
        my $fn_in_epub = $ch->{title} . ".html";

        my $id = $epub->add_xhtml($fn_in_epub, $ch->{content}, linear => "yes");
        my $np = $epub->add_navpoint(
            label   => $ch->{title},
            id      => $id,
            content => $fn_in_epub
        );
    }

    $epub->pack_zip("moedict.epub");
    say "DONE: moedict.epub";
}

build_epub();
