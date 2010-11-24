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

my $sel_day = CGI::param('day');
my $sel_start = CGI::param('start');
my $sel_stop = CGI::param('stop');
my $sel_channel = CGI::param('channel');

if (CGI::param('action') eq 'record') {
    db::queue(CGI::param('id'));
} elsif (CGI::param('action') eq 'favorite') {
    db::addFavorite(CGI::param('id'));
    scheduler::scheduleFavorites();
}

header::print();

print '<h2>Listings</h2>';

print '<form><table cellpadding="5"></tr>';

print '<td><b>Date:</b></td><td><select name="day" onchange="submit()">';

for (my $i = 0; $i < db::getPref('sd_num_days'); $i++) {

    my ($y, $m, $d) = Add_Delta_Days($year, $month, $day, $i);

    my $dow = Day_of_Week($y, $m, $d);

    my $day = sprintf("%04d-%02d-%02d", $y, $m, $d);

    if (!defined($sel_day)) {
        $sel_day = $day;
    }

    print '<option value="'.$day.'"';

    if ($day eq $sel_day) {
        print ' selected';
    }
    
    print '>'.$day.' ('.Day_of_Week_to_Text($dow).')</option>';
}

print '</select></td>';

my $start_hour = 0;

if (!defined($sel_start) or !length($sel_start)) {
    $sel_start = '00:00';
}

if ($sel_day eq $now_day) {
    $start_hour = $hour;
    $sel_start = sprintf("%02d:59", $start_hour - 1);
}

if (!defined($sel_stop) or !length($sel_stop)) {
    $sel_stop = '24:00';
}

print '<td><b>Start:</b></td><td><select name="start" onchange="submit()">';

for (my $i = $start_hour; $i < 24; $i++) {

    my $val = sprintf("%02d:00", $i);

    print '<option value="'.$val.'"';

    if ($sel_start eq $val) {
        print ' selected';
    }

    print '>'.$val.'</option>';
}

print '</select></td>';

print '<td><b>Stop:</b></td><td><select name="stop" onchange="submit()">';

for (my $i = 1; $i <= 24; $i++) {

    my $val = sprintf("%02d:00", $i);

    print '<option value="'.$val.'"';

    if ($sel_stop eq $val) {
        print ' selected';
    }

    print '>'.$val.'</option>';
}

print '</select></td>';

my $programs = db::getPrograms($sel_day, $sel_start, $sel_stop, $sel_channel);

my $stations = db::getStations();

print '<td><b>Channel:</b></td><td><select name="channel" onchange="submit()">';

print '<option></option>';

foreach my $channel (@{$stations}) {

    print '<option value="'.$channel.'"';

    if ($sel_channel eq $channel) {
        print ' selected';
    }

    print '>'.$channel.'</option>';
}

print '</select></td>';

print '</tr></table></form>';
print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc">
    <th></th>
    <th>Time</th>
    <th>Duration</th>
    <th>Channel</th>
    <th align="left">Title</th>
    <th align="left">Subtitle</th>
    </tr>';

my $counter = 0;

my $queue = db::getQueue();
my %queue_hash;

foreach my $p (@{$queue}) {
    my $key = $p->{program_id}.$p->{station_id}.$p->{start_time};
    $queue_hash{$key} = 1;
}

my $favorites = db::getFavorites();
my %favorite_hash;

foreach my $p (@{$favorites}) {
    my $program_id = 
        substr($p->{program_id}, 0, length($p->{program_id}) - 3);
    my $key = $program_id.$p->{station_id};
    $favorite_hash{$key} = 1;
}

foreach my $p (@{$programs}) {
    
    my $key1 = $p->{program_id}.$p->{station_id}.$p->{start_time};

    my $bgcolor = $queue_hash{$key1} ?
        '#00cc00' : ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr bgcolor="'.$bgcolor.'">';

    print '<td>';
    
    if (!$queue_hash{$key1}) {
        print '<a href="?action=record&day='.$sel_day.'&start='.$sel_start.
            '&stop='.$sel_stop.'&channel='.$sel_channel.
            '&id='.$p->{'schedule_id'}.'">Record</a>';
    }
    
    my $program_id = 
        substr($p->{program_id}, 0, length($p->{program_id}) - 3);
        
    my $key2 = $program_id.$p->{station_id};

    if (!$favorite_hash{$key2}) {
        if (!$queue_hash{$key1}) {
            print '&nbsp;|&nbsp;';
        }
        print '<a href="?action=favorite&day='.$sel_day.'&start='.$sel_start.
            '&stop='.$sel_stop.'&channel='.$sel_channel.
            '&id='.$p->{'schedule_id'}.'">Favorite</a>';
    }
    
    print '</td>';

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

