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
<table style="font-size: 20px; font-family: 'HAN NOM A', 'HAN NOM B', serif;">
EOF

while ($line = <STDIN>) {
    if (($moecode, $uchar)=$line=~/^([0-9a-f]{4}) (.*)$/){
        print "<tr><td>$moecode</td><td>$uchar</td><td><img src='http://140.111.34.46/dict/fonts/$moecode.gif'></td><td><img src='http://dict.revised.moe.edu.tw/images/$moecode.jpg'></td>";
        if (length($uchar) == 1){
            $ord = sprintf("%x", ord($uchar));
            print "<td><a href='http://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=$ord'><img src='http://www.unicode.org/cgi-bin/refglyph?24-$ord'> →</a></td>";
        }
        print "</tr>\n";
    }
}

print <<EOF;
</table></body></html>
EOF
