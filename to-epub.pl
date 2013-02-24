#!/usr/bin/ev perl
use v5.14;
use strict;
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
use JSON;
use Mojo::Template;
use List::MoreUtils qw(uniq);

sub mt { state $mt = Mojo::Template->new }

sub sort_by_cjk_strokes {
    state $sorter = Unicode::Collate->new(overrideCJK => \&Unicode::Collate::CJK::Stroke::weightStroke);
    return $sorter->sort(@_);
}

sub load_whole_dict {
    state $dict = JSON::decode_json(read_file("../moedict-data/dict-revised.json"));
    state $chars_with_radical = do {
        my $x = {};
        for my $char (@$dict) {
            push @{ $x->{$char->{radical}} ||=[]}, $char;
        }
        $x;
    };
    return ($dict, $chars_with_radical);
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

    my ($dict, undef) = load_whole_dict();
    @radicals = uniq grep { $_ } map { $_->{radical} } @$dict;
    @radicals = sort_by_cjk_strokes @radicals;
    return @radicals;
}

sub chars_with_radical {
    my $radical = shift;
    my ($dict, $chars_with_radical) = load_whole_dict();
    return $chars_with_radical->{$radical};
}

sub build_chapter {
    my ($radical, $characters) = @_;
    my $title = "$radical 部";
    my $content = "";

    for my $c (@$characters) {
        my $h = $c->{heteronyms};
        $content .= mt->render_file("views/character.html.ep", $c->{title}, $h);
    }

    $content = mt->render_file("views/chapter.html.ep", $title, $content);

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
    $epub->add_meta_item('cover', $epub->copy_image('img/icon.png', 'icon.png'));

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
