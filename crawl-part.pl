#!/usr/bin/env perl
#
# 爬取部首筆畫 html 用的程式
# 原始 big5 編碼之 html 檔存於 data/radical-stroke/ 目錄下
# 同時另外轉存成 utf8 編碼存於同目錄，副檔名 .utf8.html
#

use v5.14;
use strict;
use warnings;
use URI::Escape qw(uri_escape);
use File::Slurp qw(write_file read_file);
use Encode qw(encode decode);
use Mojo::UserAgent;

my $sym = { map { split / / } split /\n/, read_file("sym.txt", {binmode => ":utf8"})};

my $url = "http://dict.revised.moe.edu.tw/part1.html";

my $ua = Mojo::UserAgent->new;

binmode STDOUT, ":utf8";

my @parts;
my $part1 = $ua->get($url)->res;
$part1->dom->find("a")->each(
    sub {
        # bytes in big5 encoding.
        my $char_raw = $_->attrs("href") =~ s!\Ajavascript:part\(\'(.+)'\)\z!$1!r;
        my $part;

        my $char;
        if ($char = $sym->{ lc($char_raw) }) {
            $part = "%" . substr($char_raw,0,2) . "%" . substr($char_raw,2,2);
        }
        else {
            $part = uri_escape($char_raw);
            $char = decode big5 => $char_raw;
        }

        push @parts, { char => $char, url => "http://dict.revised.moe.edu.tw/cgi-bin/newDict/part.sh?part=${part}&strokeEx=100&imgFont=1" }
    }
);

write_file "data/radical-stroke/part1.html", $part1->body;
write_file "data/radical-stroke/part1.utf8.html", encode utf8 => decode big5 => $part1->body =~ s!charset=\Kbig5!utf-8!r;

for my $part (@parts) {
    my $x = $ua->get($part->{url})->res;
    write_file "data/radical-stroke/part.$part->{char}.html", $x->body;
    write_file "data/radical-stroke/part.$part->{char}.utf8.html", encode utf8 => decode big5 => $x->body =~ s!charset=\Kbig5!utf-8!r;
}
