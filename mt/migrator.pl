#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use DBI;
use Data::Dumper;
use YAML 'Dump';
use autodie;

## convert MT5 to jekyll-bootstrap

mkdir("$Bin/_posts") unless -d "$Bin/_posts";

my $dns  = "DBI:mysql:database=mt;";
my $dbh = DBI->connect($dns, 'root', 'fayland', {
    PrintError => 1,    # print Error when MySQL goes wrong
    RaiseError => 1,
    AutoCommit => 1     # commit, no delay
} ) or die $DBI::errstr;

$dbh->{mysql_enable_utf8} = 1;
$dbh->do("SET names utf8");

# get tags
my $tag_sth = $dbh->prepare("SELECT tag_name FROM mt_objecttag JOIN mt_tag ON mt_tag.tag_id=mt_objecttag.objecttag_tag_id WHERE objecttag_object_datasource='entry' AND objecttag_object_id = ?");

my $sth = $dbh->prepare("SELECT entry_id, entry_basename, entry_text, entry_text_more, entry_authored_on, entry_title, entry_convert_breaks FROM mt_entry");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    print Dumper(\$row);

    my $slug = $row->{entry_basename};
    $slug =~ s/\_/-/g;

    my $date = $row->{entry_authored_on};
    my $d = substr($date, 0, 10);

    my $entry_convert_breaks = $row->{entry_convert_breaks};
    die unless $entry_convert_breaks eq 'richtext'; # I only have richtext

    my $content = $row->{entry_text};
    $content .= "\n" . $row->{entry_text_more} if $row->{entry_text_more};

    # get tags
    my @tags;
    $tag_sth->execute($row->{entry_id});
    while (my ($t) = $tag_sth->fetchrow_array) {
        push @tags, $t;
    }

    my $file = "$Bin/_posts/$d-$slug.html";
    my $data = {
        layout => 'post',
        title  => $row->{entry_title},
        category => "perl", # I do not have category created
        tags => \@tags,
    };
    my $out = Dump($data) . "---\n" . '{% include JB/setup %}' . "\n\n" . $content;
    open(my $fh, '>:utf8', $file);
    print $fh $out;
    close($fh);
}

$dbh->disconnect;

1;