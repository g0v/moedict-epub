#!/usr/bin/env perl
use v5.14;
use utf8;
use encoding 'utf8';
use strict;
use File::Slurp;
use Encode qw(encode decode);
use Mojo::DOM;
use JSON;

my %sym = map { chomp; (split / +/) } read_file("sym.txt", { binmode => ":utf8"});

my %radical_id = map { chomp; (split(/[; ']+/,$_))[2,0,1,0] } grep {/^\d/} read_file("data/UNIDATA/CJKRadicals.txt");
# ｜(FF5C) => ⼁ 2F01
# 青(9752) => 靑 9751
$radical_id{"FF5C"} = $radical_id{"2F01"};
$radical_id{"9752"} = $radical_id{"9751"};

sub strokes_to_int {
    my $strokes = shift;
    $strokes =~ s!畫$!!;
    $strokes =~ y!０一二三四五六七八九!0123456789!;
    $strokes =~ s!^十$!10!;
    $strokes =~ s!^十!1!;
    $strokes =~ s!十$!0!;
    return $strokes;
}

sub parse_part_file {
    my ($part_file) = @_;
    my $raw_radical = ($part_file =~ /part.(.+).utf8.html/)[0];
    my $radical = decode utf8 => $raw_radical;
    my $radical_hex = sprintf("%X",ord($radical));
    my $radical_id = $radical_id{$radical_hex};

    my $stroke_to_chars = {};
    my $html = read_file($part_file, {binmode => ":utf8"});
    my $dom = Mojo::DOM->new($html);
    $dom->find("tr")->first->remove;
    $dom->find("table a")->each(
        sub {
            my $strokes_zh = $_->parent->parent->find("th")->first->text;
            my $strokes = strokes_to_int($strokes_zh);
            my $char = ($_->attrs("href") =~ (m!'(.+)'!))[0]; # marmot ?
            if (length($char) > 1) {
                $char = $sym{$char};
            }
            push @{$stroke_to_chars->{$strokes}}, $char;
        }
    );

    return ($radical_id, $stroke_to_chars);
}

my $part1_file = "data/radical-stroke/patr1.utf8.html";
my @part_files = <data/radical-stroke/part.*.utf8.html>;

my $radical_strokes_index = {};
for my $part_file (@part_files) {
    my ($radical_id, $stroke_to_chars) = parse_part_file($part_file);
    $radical_strokes_index->{$radical_id} = $stroke_to_chars;
}


my $json_encoder = JSON->new->pretty;

write_file "data/radical_strokes.json", { binmode => ":utf8" }, $json_encoder->encode($radical_strokes_index);
say "data/radical_strokes.json is produced";
