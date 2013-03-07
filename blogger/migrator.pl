#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use Data::Dumper;
use YAML 'Dump';
use autodie;
use HTML::TreeBuilder;

## convert blogger local files to jekyll-bootstrap

mkdir("$Bin/_posts") unless -d "$Bin/_posts";

my $dir = "$Bin/blog";
opendir(my $df, $dir);
my @years = grep { /^\d+$/ and -d "$dir/$_" } readdir($df); # only 2006, 2010 etc.
closedir($df);

foreach my $year (@years) {
    opendir($df, "$dir/$year");
    my @months = grep { /^\d+$/ and -d "$dir/$year/$_" } readdir($df); # only 01 etc.
    closedir($df);
    foreach my $month (@months) {
        opendir($df, "$dir/$year/$month");
        my @html = grep { /\.html$/ } readdir($df);
        closedir($df);

        foreach my $html_file (@html) {
            print "# on $dir/$year/$month/$html_file\n";
            open(my $fh, '<:utf8', "$dir/$year/$month/$html_file");
            my $content = do { local $/; <$fh>; };
            close($fh);

            my $tree = HTML::TreeBuilder->new_from_content($content);
            my $date = $tree->look_down(_tag => 'span', class => 'date-header')->as_trimmed_text;
            my ($day) = ($date =~ /(\d+)\,/); # Thursday, March 23, 2006
            my $title = $tree->look_down(_tag => 'h3', class => 'post-title')->as_trimmed_text;
            # <div class="post-body">
            my ($body)  = ($content =~ m{<div class="post-body">\s*<div>(.*?)</div>\s*</div>\s*<p class="post-footer">}is);
            die unless $body;

            # <p class="blogger-labels">Labels: <a rel='tag' href="http://www.fayland.org/blog/labels/Moose.html">Moose</a></p>
            $body =~ s{<p class="blogger-labels">Labels(.*?)</p>}{}s;
            $body =~ s/^\s+|\s+$//g;
            $body =~ s{^<div style="clear:both;"></div>}{}s;
            $body =~ s{<div style="clear:both; padding-bottom:0.25em"></div>$}{}s;

            my $labels = $tree->look_down(_tag => 'p', class => 'blogger-labels');
            my @tags = $labels ? $labels->look_down(_tag => 'a', rel => 'tag') : ();
            @tags = map { $_->as_trimmed_text } @tags;

            my $dt = sprintf('%04d-%02d-%02d', $year, $month, $day);
            my $file = "$Bin/_posts/$dt-$html_file";
            my $data = {
                layout => 'post',
                title  => $title,
                category => "perl", # I do not have category created
                tags => \@tags,
            };
            my $out = Dump($data) . "---\n" . '{% include JB/setup %}' . "\n\n" . $body;
            open($fh, '>:utf8', $file);
            print $fh $out;
            close($fh);

            $tree = $tree->delete;
        }
    }
}

1;