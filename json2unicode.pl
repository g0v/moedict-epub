#!/usr/bin/env perl
# 用法：perl json2unicode.pl > dict-revised.unicode.json
#
# 如欲使用 fontforge/HANNOMMoEExtra-Regular 的 PUA 字形，請改用：
# perl json2unicode.pl sym-pua.txt > dict-revised.pua.json
#
use strict;
use utf8;
use encoding 'utf8';
use FindBin '$Bin';
die "dict-revised.json not in current directory!" unless -s "dict-revised.json";
my %map = do {
    local $/;
    open my $fh, '<:utf8', (@ARGV ? $ARGV[0] : "$Bin/sym.txt") or die $!;
    map { split(/\s+/, $_, 2) } split(/\n/, <$fh>);
};
my $re = join '|', keys %map;
my $compat = join '|', map { substr($_, 1) } grep /^x/, keys %map;
open my $dump, '<:utf8', 'dict-revised.json';
my $seen_fcf2 = 0;
local $/;
while (<$dump>) {
    s< "\{\[ ($compat) \]\}" >
     < '"'.($map{"x$1"} || $map{$1}) . '"' >egx;
    s< \{\[ ($re) \]\} >< $map{$1} >egx;
    print;
}
