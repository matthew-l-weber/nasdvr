#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use header;
use footer;
use hdhr;
use logger;

db::init();

print CGI::header();

if (CGI::param('action') eq 'cancel') {
    db::cancel(CGI::param('id'));
}

header::print(30);

print '<h2>Queue</h2>';

print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc">
    <th></th>
    <th>Date</th>
    <th>Time</th>
    <th>Duration</th>
    <th>Channel</th>
    <th align="left">Title</th>
    <th align="left">Subtitle</th>
    <th>Status</th>
    </tr>';

my $counter = 0;

my $programs = db::getQueue();

foreach my $p (@{$programs}) {

    my $status = length($p->{tuner}) ?
        'Recording on Tuner '.$p->{tuner} : '';

    my $color = length($p->{tuner}) ? '#00cc00' :
        ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr bgcolor="'.$color.'">';

    if (!length($p->{tuner})) {
        print '<td><a href="?action=cancel&id='.
            $p->{queue_id}.'">Cancel</a></td>';
    } else {
        print '<td></td>';
    }

    my ($d, $t) = split(/ /, $p->{time});

    print '<td align="center">'.$d.'</td>'.
        '<td align="center">'.$t.'</td>'.
        '<td align="center">'.$p->{duration}.'</td>'.
        '<td align="center">'.$p->{station}.'</td>'.
        '<td>'.$p->{title}.'</td>'.
        '<td>'.$p->{subtitle}.'</td>'.
        "<td>$status</td>".
        '</tr>';
		
	$counter++;
}

print '</table>';

footer::print();

