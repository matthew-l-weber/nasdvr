#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use header;
use footer;

db::init();

print CGI::header(30);

if (CGI::param('action') eq 'delete') {
    db::deleteRecording(CGI::param('id'));
}

header::print();

print '<h2>Recorded</h2>';

print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc">
    <th></th>
    <th>Date/Time</th>
    <th>Duration</th>
    <th>Channel</th>
    <th align="left">Title</th>
    <th align="left">Subtitle</th>
    </tr>';

my $counter = 0;

my $programs = db::getRecorded();

foreach my $p (@{$programs}) {

    my $color = ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr>';

    print '<td><a href="?action=delete&id='.
        $p->{'record_id'}.'">Delete</a></td>';

    print '<td align="center">'.$p->{'time'}.'</td>'.
        '<td align="center">'.$p->{'duration'}.'</td>'.
        '<td align="center">'.$p->{'station'}.'</td>'.
        '<td>'.$p->{'title'}.'</td>'.
        '<td>'.$p->{'subtitle'}.'</td>'.
        '</tr>';

    $counter++;
}

print '</table>';

footer::print();

