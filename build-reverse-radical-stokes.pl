#!/usr/bin/env perl

use v5.14;
use JSON;
use File::Slurp;

my $radical_strokes = from_json(scalar read_file "data/radical-strokes.json", { binmode => ":utf8" });

my $characters = {};
for my $radical (keys %$radical_strokes) {
    for my $strokes (keys %{$radical_strokes->{$radical}}) {
        for my $c (@{ $radical_strokes->{$radical}{$strokes} }) {
            $characters->{$c} = {
                radical => $radical,
                strokes => $strokes
            };
        }
    }
}

write_file "data/reverse-radical-strokes.json", to_json($characters, { utf8 => 1, pretty => 1 });
say "data/reverse-radical-strokes.json produced";
