#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use Data::Dumper;
use YAML 'Dump';
use autodie;
use HTML::TreeBuilder;

## convert custom Eplanet to jekyll-bootstrap

mkdir("$Bin/_posts") unless -d "$Bin/_posts";

my $dir = "$Bin/journal";
opendir(my $df, $dir);
my @html = grep { /\.html$/ } readdir($df);
closedir($df);

foreach my $html_file (@html) {
    print "# on $dir/$html_file\n";
    open(my $fh, '<:utf8', "$dir/$html_file");
    my $content = do { local $/; <$fh>; };
    close($fh);

    next if $content =~ m{<div class="right_float_text">};

    my $tree = HTML::TreeBuilder->new_from_content($content);
    # Created on <span class="digit">2006-03-01 00:12:50</span>
    my ($date) = ($content =~ m{Created on <span class="digit">([\d\-\:\s]+)</span>});
    die unless $date;
    $date = substr($date, 0, 10);

    my $title = $tree->look_down(_tag => 'h1')->as_trimmed_text;

    # <div class='content'>
    # </div>
    # <p><&lt;Previous
    my ($body)  = ($content =~ m{<div class='content'>\s*(.*?)</div>\s*\s*<p>\S+(Previous|Next)}is);
    die unless $body;

    # <p>Category: <a href='ShareURL.html'>ShareURL</a> &nbsp; Keywords: <b>ShareURL</b></p>
    $body =~ s{<p>Category:\s*(.*?)</p>}{}s;

    my $file = "$Bin/_posts/$date-$html_file";
    my $data = {
        layout => 'post',
        title  => $title,
        category => "perl", # I do not have category created
        tags => [],
    };
    my $out = Dump($data) . "---\n" . '{% include JB/setup %}' . "\n\n" . $body;
    open($fh, '>:utf8', $file);
    print $fh $out;
    close($fh);

    $tree = $tree->delete;
}

1;