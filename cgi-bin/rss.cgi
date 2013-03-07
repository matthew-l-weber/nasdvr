#!/usr/bin/perl

use strict;
use lib '../lib';
use db;

db::init();

my $programs = db::getRecorded();

print "content-type: application/rss+xml\n\n";

print qq |<?xml version="1.0"?>
<rss version="2.0">
<channel>
<title>NASDVR</title>
<link>|.db::getPref('recording_url').
qq |</link><description>NASDVR</description>
|;

my @sorted = sort { lc($a->{title}) cmp lc($b->{title}) } @{$programs};

foreach my $p (@sorted) {

    my $time = substr($p->{start_time}, 0, 10).' '.
            substr($p->{start_time}, 11, 5);

    print '<item>';
    print '<category>'.$p->{title}.'</category>';
    print '<title>'.$p->{title}.' - '.$time.'</title>';
    print '<link>'.db::getPref('recording_url').'/'.$p->{'filename'}.'</link>';
    print '<description></description>';
    print '</item>';
}

print qq |
</channel>
</rss>
|;

