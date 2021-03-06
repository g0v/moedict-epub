#!/usr/bin/env perl
# 用法：perl db2unicode.pl | sqlite3 dict-revised.unicode.sqlite3
#
# 如欲使用 fontforge/HANNOMMoEExtra-Regular 的 PUA 字形，請改用：
# perl db2unicode.pl sym-pua.txt | sqlite3 dict-revised.pua.sqlite3
#
use strict;
use utf8;
use encoding 'utf8';
use FindBin '$Bin';

my %map = do {
    local $/;
    open my $fh, '<:utf8', (@ARGV ? $ARGV[0] : "$Bin/sym.txt") or die $!;
    map { split(/\s+/, $_, 2) } split(/\n/, <$fh>);
};
my $re = join '|', keys %map;
my $compat = join '|', map { substr($_, 1) } grep /^x/, keys %map;
if (-s "dict-revised.sqlite3") {
    system("sqlite3 dict-revised.sqlite3 .dump > dict-revised.sqlite3.dump");
    open my $dump, '<:utf8', 'dict-revised.sqlite3.dump';
    local $/;
    while (<$dump>) {
        s< (['"])\{\[ ($compat) \]\}\1 >
         < $1.($map{"x$2"} || $map{$2}).$1 >egx;
        s< \{\[ ($re) \]\} >< $map{$1} >egx;
        print;
    }
    exit;
}
else {
    warn "dict-revised.sqlite3 not in current directory, assuming old DB in development.sqlite3"
}

die "development.sqlite3 not in current directory!" unless -s "development.sqlite3";
system("sqlite3 development.sqlite3 .dump > development.sqlite3.dump");
open my $dump, '<:utf8', 'development.sqlite3.dump';
my $seen_fcf2 = 0;
while (<$dump>) {
    $seen_fcf2++ if m{images/fcf2\.jpg};
    $map{fcf2} = '不' if $seen_fcf2 > 2;
    s!'<img src="images/($compat).jpg" border="0" />(?:&nbsp;)?'!"'".($map{"x$1"} || $map{$1}) . "'"!eg;
    s!<img src="images/($re).jpg" border="0" />(?:&nbsp;)?!$map{$1}!eg;
    s!<span class="key">!!g;
    s!</?t[^>]*>!!g;
    s!<br/?>!\n!g;
    s!'｜'!'⼁'!g; # 2F01 is the character
    s!｜，!⼁，!g; # 2F01 is the character (in its own definition)
    s!｜!ㄧ!g; # This is the phonetic symbol
    s!˙!．!g;
    print;
}
