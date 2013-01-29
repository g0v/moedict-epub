#!/usr/bin/env perl
# 用法：perl db2unicode.pl | sqlite3 development.unicode.sqlite3
use strict;
use utf8;
use encoding 'utf8';
use FindBin '$Bin';
die "development.sqlite3 not in current directory!" unless -s "development.sqlite3";
open my $fh, '<:utf8', "$Bin/sym.txt";
my %map = map { split(/\s+/, $_, 2) } <$fh>;
my $re = join '|', keys %map;
my $body = `sqlite3 development.sqlite3 .dump`;
$body =~ s!<img src="images/($re).jpg" border="0" />(?:&nbsp;)?!$map{$1}!eg;
$body =~ s!<span class="key">!!g;
print $body;
