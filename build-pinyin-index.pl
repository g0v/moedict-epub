#!/usr/bin/env perl
use v5.14;
use utf8;
use JSON;
use File::Slurp;
use Unicode::Normalize;

sub insert_index {
    my ($idx, $title, $terms) = @_;

    my (%pos, %freq);
    for (my $i = 0; $i < @$terms; $i++) {
        my $t = $terms->[$i];
        $freq{$t}++;
        push @{$pos{$t}},$i;
    }
    for my $t (keys %freq) {
        $idx->{$t}{$title} //= [$pos{$t}[0], 0];
        $idx->{$t}{$title}[1] += $freq{$t};
    }
}

sub sort_index {
    my $idx = shift;
    reset(%$idx);
    while (my ($term, $docs) = each %$idx) {
        my @rows = map {
            [ $_, $docs->{$_}[0], $docs->{$_}[1] ]
        } sort {
            length($a) <=> length($b)
            || $docs->{$a}[0] <=> $docs->{$b}[0]
            || $docs->{$b}[1] <=> $docs->{$a}[1]
        } keys %$docs;
        $idx->{$term} = \@rows;
    }
}

binmode STDERR, ":utf8";

my $dict = from_json(scalar read_file "dict-revised-unicode.json", { binmode => ":utf8" });

my %pinyin;
my %pinyin_numerical_tone;
my %pinyin_sans_tone;

my %tones = ( "\x{304}" => 1 , "\x{301}" => 2, "\x{30c}" => 3 , "\x{300}" => 4 );
my $tone_re = "(" . join("|", keys %tones) . ")";

for (my $i = 0; $i < @$dict; $i++) {
    my $entry = $dict->[$i];
    for my $heteronym (@{ $entry->{heteronyms} }) {
        next unless $heteronym->{pinyin};

        for my $p (split /\s*\(變\)\s*/, $heteronym->{pinyin}) {
            # strip comments like:（讀音）(又音)(語音)
            $p =~ s/（.音）//g;
            $p =~ s/\(.音\)//g;
            $p = NFD($p);

            my $p0 = $p =~ s! $tone_re !!xgr =~ s/u\x{308}/v/gr;

            my $p1 = $p =~ s! $tone_re !$tones{$1}!xgr =~ s/u\x{308}/v/gr;
            $p1 =~ s{([1234])(\S+)}{$2$1}g;

            if ($p1 !~ /\A[ a-z1234]+\z/) {
                say STDERR "This looks weird: $p";
            } else {
                my $title = $entry->{title};
                insert_index(\%pinyin, $title, [split /\s+/, $p]);
                insert_index(\%pinyin_sans_tone, $title, [split /\s+/, $p0]);
                insert_index(\%pinyin_numerical_tone, $title, [split /\s+/, $1]);
            }
        }
    }
}

sort_index(\%pinyin);
sort_index(\%pinyin_sans_tone);
sort_index(\%pinyin_numerical_tone);

my $JSON = JSON->new->pretty->utf8->canonical;
write_file "data/index-pinyin.json", $JSON->encode(\%pinyin);
write_file "data/index-pinyin-sans-tone.json", $JSON->encode(\%pinyin_sans_tone);
write_file "data/index-pinyin-numerical-tone.json", $JSON->encode(\%pinyin_numerical_tone);
