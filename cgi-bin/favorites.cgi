#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use Date::Calc qw( Add_Delta_Days Day_of_Week Day_of_Week_to_Text );
use header;
use footer;
use scheduler;

db::init();

print CGI::header();

my $query = CGI::param('query');

if (CGI::param('action') eq 'delete') {
    scheduler::unscheduleFavorites();
    db::deleteFavorite(CGI::param('id'));
    scheduler::scheduleFavorites();
}

header::print();

print '<h2>Favorites</h2>';

print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc">
    <th></th>
    <th>Channel</th>
    <th align="left">Title</th>
    </tr>';

my $counter = 0;

my $favorites = db::getFavorites();

foreach my $p (@{$favorites}) {

    my $bgcolor = ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr bgcolor="'.$bgcolor.'">';

    print '<td><a href="?action=delete&id='.
        $p->{'favorite_id'}.'">Delete</a></td>';

    print '<td align="center">'.$p->{'station'}.'</td>'.
        '<td>'.$p->{'title'}.'</td>'.
        '</tr>';

    $counter++;
}

print '</table>';

footer::print();

