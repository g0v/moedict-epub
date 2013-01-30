#!/usr/bin/perl
use utf8;
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
print <<EOF;
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Characters</title>
</head>
<body>
<pre style="font-size: 20px;">
EOF

$unicodeeval = sub{
    ($f, $a) = @_;
    return "<a href=\"http://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=$a\">U+$a <img src=\"http://www.unicode.org/cgi-bin/refglyph?24-$1\"></a>";
};

$cnseval = sub{
    ($a, $b) = @_;
    $page = sprintf("%x", int $a);
    $code = $b;
    return "<a href=\"http://www.cns11643.gov.tw/AIDB/query_general_view.do?page=$page&code=$code\">CNS $a-$b <img src=\"http://www.cns11643.gov.tw/cgi-bin/ttf2png?page=$a&number=$b&face=sung&fontsize=26\"></a>";
};

$vareval = sub{
    # http://dict.variants.moe.edu.tw/yitib/ydb/ydb06239.htm#bm_001
    # http://dict.variants.moe.edu.tw/sword/swordb/sb06239/001.jpg
    ($a, $b, $c) = @_;
    return "<a href=\"http://dict.variants.moe.edu.tw/yiti$a/yd$a/yd$a$b.htm#bm_$c\">$a$b-$c <img src=\"http://dict.variants.moe.edu.tw/sword/sword$a/s$a$b/$c.jpg\"></a>";
};

$vareval_canonical = sub{
    # http://dict.variants.moe.edu.tw/yitib/ydb/ydb06239.htm
    ($a, $b) = @_;
    return "<a href=\"http://dict.variants.moe.edu.tw/yiti$a/yd$a/yd$a$b.htm\">VAR $a$b</a>";
};

$moeeval = sub{
    # http://dict.variants.moe.edu.tw/yitib/ydb/ydb06239.htm
    ($a) = @_;
    return "MOE $a <img src='http://140.111.34.46/dict/fonts/$a.gif'><img src='http://dict.revised.moe.edu.tw/images/$a.jpg'>";
};

while ($line = <STDIN>) {
    $line =~ s/U\+([0-9a-fA-F]{4,5})/$unicodeeval->($0,$1)/ge; # unicode
    $line =~ s/CNS (\d+)-([0-9a-fA-F]{4})/$cnseval->($1,$2)/ge; # CNS11643
    $line =~ s/([a-zA-Z])(\d{5})\-(\d{3})/$vareval->($1,$2,$3)/ge; # Variant
    $line =~ s/VAR ([a-zA-Z])(\d{5})/$vareval_canonical->($1,$2)/ge; # Variant Canonical
    $line =~ s/MOE [\da-fA-F]{4}/$moeeval->($0)/ge; # MoE dictionary encoding
    print $line;
}

print <<EOF;
</pre></body></html>
EOF
