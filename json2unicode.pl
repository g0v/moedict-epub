#!/usr/bin/env perl
# 用法：perl json2unicode.pl > output.unicode.json
#
# 如欲使用 fontforge/HANNOMMoEExtra-Regular 的 PUA 字形，請改用：
# perl json2unicode.pl sym-pua.txt > output.unicode.json
#
use strict;
use utf8;
use encoding 'utf8';
use FindBin '$Bin';
die "output.json not in current directory!" unless -s "output.json";
my %map = do {
    local $/;
    open my $fh, '<:utf8', (@ARGV ? $ARGV[0] : "$Bin/sym.txt") or die $!;
    map { split(/\s+/, $_, 2) } split(/\n/, <$fh>);
};
my $re = join '|', keys %map;
my $compat = join '|', map { substr($_, 1) } grep /^x/, keys %map;
open my $dump, '<:utf8', 'output.json';
my $seen_fcf2 = 0;
local $/;
while (<$dump>) {
    tr!\x{FF21}-\x{FF3A}\x{FF41}-\x{FF5A}!A-Za-z!;
    s!["「]\K｜!⼁!g; # 2F01 is the character
    s!｜!ㄧ!g; # This is the phonetic symbol
    s!˙!．!g; # middle dot
    s< "\{\[ ($compat) \]\}" >
     < '"'.($map{"x$1"} || $map{$1}) . '"' >egx;
    s< \{\[ ($re) \]\} >< $map{$1} >egx;
    print;
}
