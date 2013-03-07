#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use Date::Calc qw( Add_Delta_Days Day_of_Week Day_of_Week_to_Text );
use header;
use footer;
use scheduler;
use util;

db::init();

my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime(time);

$year += 1900;
$month++;

my $now_day = sprintf("%04d-%02d-%02d", $year, $month, $day);

print CGI::header();

my $sel_day = CGI::param('day');

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

print '</select></td></tr></table></form><p>';

my $programs = db::getPrograms($sel_day, '00:00', '23:00', '');

my $stations = db::getStations();

#@{$stations} = ('4.1');

print '<table cellpadding="5" cellspacing="1" bgcolor="#000000">';

print "<tr align='center'>";

for (my $i = 0; $i <= 48; $i++) {

    if ($i == 0) {
        print "<td bgcolor='#cccccc'></td>";
    }
    
    my $min = $i % 2 ? '30' : '0';
    
    my $hour = $i / 2;
    my $suffix = 'am';
    
    if ($i > 23) {
        $hour = $hour - 12;
        $suffix = 'pm';
    }
    
    if ($hour < 1) {
        $hour = 12;
    }
    
    my $hour = sprintf("%2d:%02d%s", $hour, $min, $suffix);

    print "<td bgcolor='#cccccc'>$hour</td>";
    
}

print "</tr>";

my $queue = db::getQueue();
my %queue_hash;

foreach my $p (@{$queue}) {
    $p->{time} = substr($p->{start_time}, 11, 5);
    my ($h, $m) = split(/:/, $p->{time});
    if ($m < 30) {
        $p->{time} = $h.':00';
    } else {
        $p->{time} = $h.':30';
    }               
    my $key = $p->{station}.$p->{time};
    $queue_hash{$key} = $p;
}

my %program_hash;

foreach my $p (@{$programs}) {
    
    $p->{time} = substr($p->{start_time}, 11, 5);
    my ($h, $m) = split(/:/, $p->{time});
    if ($m < 30) {
        $p->{time} = $h.':00';
    } else {
        $p->{time} = $h.':30';
    }               
    my $key = $p->{station}.$p->{time};
    
    my ($h, $m) = split(/:/, $p->{duration});
    my $blocks = 2 * $h;
    if ($m > 0) {
        if ($m <= 30) {
            $blocks++;
        } else {
            $blocks += 2;
        }
    }
    
    $p->{blocks} = $blocks;
    
#    if ($p->{station} eq '4.1') {
#        print "$key<br>";
#        print $p->{title}.' - '.$p->{time}.' - '.$p->{duration}.' - '.$p->{blocks}."<br>";
#    }
    
    $program_hash{$key} = $p;
}

foreach my $channel (@{$stations}) {
    
    print "<tr align='center'>";
        
    for (my $i = 0; $i <= 48; $i++) {

        if ($i == 0) {
            print "<td bgcolor='#cccccc'>$channel</td>";
        }
        
        my $min = $i % 2 ? '30' : '0';

        my $hour = sprintf("%02d:%02d", $i / 2, $min);

        my $found = 0;
        
        my $key = $channel.$hour;
        #print "$key<br>";
        my $p = $program_hash{$key};

        if (defined($p)) {
            
#    if ($p->{station} eq '4.1') {
#        print $p->{title}.' - '.$p->{time}.' - '.$p->{duration}.' - '.$p->{blocks}."<br>";
#    }
    
            
            
            my $q = $queue_hash{$key};
                        
            my $record = 0;
        
            if ($q->{program_id} eq $p->{program_id}) {
                $record = 1;
            }
            
            my ($h, $m) = split('\:', $p->{time});
            
            if ($m < 30) {
                $p->{time} = $h.':00';
            } else {
                $p->{time} = $h.':30';
            }
            
            if ($record) {
                print "<td colspan='".$p->{blocks}."' bgcolor='#00cc00'>".$p->{title}."<br>".$p->{subtitle}."</td>";
            } else {
                print "<td colspan='".$p->{blocks}."' bgcolor='#ffffff'><a href='?action=record&id=".$p->{schedule_id}."'>".$p->{title}."<br>".$p->{subtitle}."</a></td>";
            }
            
            $i += $p->{blocks} - 1;
            
        } else {
            print "<td bgcolor='#ffffff'>&nbsp;</td>";
        }    
        
    }
    
    print "</tr>";    
}

print '</table>';

footer::print();

