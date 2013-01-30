#!/usr/bin/env perl
# 用法：perl db2unicode.pl | sqlite3 development.unicode.sqlite3
#
# 如欲使用 fontforge/HANNOMMoEExtra-Regular 的 PUA 字形，請改用：
# perl db2unicode.pl sym-pua.txt | sqlite3 development.pua.sqlite3
#
use strict;
use utf8;
use encoding 'utf8';
use FindBin '$Bin';
die "development.sqlite3 not in current directory!" unless -s "development.sqlite3";
my %map = do {
    local $/;
    open my $fh, '<:utf8', (@ARGV ? $ARGV[0] : "$Bin/sym.txt") or die $!;
    map { split(/\s+/, $_, 2) } split(/\n/, <$fh>);
};
my $re = join '|', keys %map;
system("sqlite3 development.sqlite3 .dump > development.sqlite3.dump");
open my $dump, '<:utf8', 'development.sqlite3.dump';
my $seen_fcf2 = 0;
while (<$dump>) {
    $seen_fcf2++ if m{images/fcf2\.jpg};
    $map{fcf2} = '不' if $seen_fcf2 > 2;
    s!<img src="images/($re).jpg" border="0" />(?:&nbsp;)?!$map{$1}!eg;
    s!<span class="key">!!g;
    print;
}
