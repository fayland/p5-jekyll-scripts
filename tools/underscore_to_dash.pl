#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use File::Copy 'move';

my $dir = '/Users/fayland/git/fayland.me/_posts';
opendir(my $df, $dir);
my @files = grep { /\.html/ and /\_/ } readdir($df);
closedir($df);

foreach my $f (@files) {
    my $n = $f; $n =~ s/\_/\-/g;
    print "# from $f -> $n\n";
    move("$dir/$f", "$dir/$n");
}

1;