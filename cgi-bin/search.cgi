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

my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime(time);

$year += 1900;
$month++;

my $now_day = sprintf("%04d-%02d-%02d", $year, $month, $day);

print CGI::header();

my $query = CGI::param('query');

if (CGI::param('action') eq 'record') {
    db::queue(CGI::param('id'));
} elsif (CGI::param('action') eq 'favorite') {
    db::addFavorite(CGI::param('id'));
    scheduler::scheduleFavorites();
}

header::print();

print '<h2>Search</h2>';

print '<form><table cellpadding="5"></tr>';
print '<td><td><input name="query" value="'.$query.'" size=30></td>
    <td><input type="submit" value="Query"></td></tr>';
print '</tr></table></form>';
print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc">
    <th></th>
    <th>Date</th>
    <th>Time</th>
    <th>Duration</th>
    <th>Channel</th>
    <th align="left">Title</th>
    <th align="left">Subtitle</th>
    </tr>';

my $counter = 0;

my $queue = db::getQueue();
my %schedule_hash;

foreach my $p (@{$queue}) {
    my $key = $p->{program_id}.$p->{station_id}.$p->{start_time};
    $schedule_hash{$key} = 1;
}

my $favorites = db::getFavorites();
my %favorite_hash;

foreach my $p (@{$favorites}) {
    my $program_id = 
        substr($p->{program_id}, 0, length($p->{program_id}) - 3);
    my $key = $program_id.$p->{station_id};
    $favorite_hash{$key} = 1;
}

my $programs = db::getSearch($query);

foreach my $p (@{$programs}) {

    my $key1 = $p->{program_id}.$p->{station_id}.$p->{start_time};
    
    my $bgcolor = $schedule_hash{$key1} ?
        '#00cc00' : ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr bgcolor="'.$bgcolor.'">';

    print '<td>';
    
    if (!$schedule_hash{$key1}) {
        print '<a href="?action=record&id='.
            $p->{'schedule_id'}.'&query='.$query.'">Record</a>';
    }
    
    my $program_id = 
        substr($p->{program_id}, 0, length($p->{program_id}) - 3);
        
    my $key2 = $program_id.$p->{station_id};
    
    if (!$favorite_hash{$key2}) {
        if (!$schedule_hash{$key1}) {
            print '&nbsp;|&nbsp;';
        }
        print '<a href="?action=favorite&id='.
            $p->{'schedule_id'}.'&query='.$query.'">Favorite</a>';
    }

    print '</td>';
    
    my ($d, $t) = split(/ /, $p->{time});

    print '<td align="center">'.$d.'</td>'.
        '<td align="center">'.$t.'</td>'.
        '<td align="center">'.$p->{'duration'}.'</td>'.
        '<td align="center">'.$p->{'station'}.'</td>'.
        '<td>'.$p->{'title'}.'</td>'.
        '<td>'.$p->{'subtitle'}.'</td>'.
        '</tr>';

    $counter++;
}

print '</table>';

footer::print();

