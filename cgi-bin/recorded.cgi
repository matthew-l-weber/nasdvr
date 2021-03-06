#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use header;
use footer;
use util;

db::init();

print CGI::header();

my $filter_name = CGI::param('filter_name');

my $view = 0;

if (CGI::param('action') eq 'delete') {
    db::deleteRecording(CGI::param('id'));
} elsif (CGI::param('action') eq 'view') {
    $view = 1;
}

my $counter = 0;

my $programs = db::getRecorded();

header::print();

if ($view == 1) {
    
    print '<embed 
         type="application/x-vlc-plugin"
         pluginspage="http://www.videolan.org" 
         version="VideoLAN.VLCPlugin.2"
         id="vlc" width="400" height="300"
         target="'.db::getPref('recording_url').'/'.CGI::param('filename').'" />';
    
} else {

    print '<h2>Recorded</h2>';
    
    print '<form><table><tr><td><b>Filter:</b></td><td>
        <select name="filter_name" onchange="submit()">';
    print '<option value="">All Recordings</option>';
    
    my %program_hash;
    
    foreach my $p (@{$programs}) {
        $program_hash{$p->{title}} += 1;
    }
    
    foreach my $name (sort keys %program_hash) {
        my $count = $program_hash{$name};
        print "<option value=\"$name\"";
        if ($filter_name eq $name) {
            print ' selected';
        }
        print ">$name ($count)</option>";
    }
    
    print '</select></td></tr></table></form>';
    
    print '<table cellpadding="5" cellspacing="0">';
    
    print '<tr bgcolor="#cccccc">
        <th></th>
        <th></th>
        <th>Date</th>
        <th>Time</th>
        <th>Duration</th>
        <th>Channel</th>
        <th align="left">Title</th>
        <th align="left">Subtitle</th>
        </tr>';
        
    foreach my $p (@{$programs}) {
    
        if (!length($filter_name) or ($filter_name eq $p->{title})) {
    
            my $color = ($counter % 2) ? '#eeeeee' : '#ffffff';
    
            print '<tr bgcolor="'.$color.'">';
    
            print '<td><a href="?action=delete&id='.
                $p->{'record_id'}.'&filter_name='.$filter_name.'">Delete</a></td>';

            print '<td><a href="'.db::getPref('recording_url').'/'.$p->{filename}.'">View</a></td>';
			
            my ($d, $t) = split(/ /, $p->{time});
    
            print '<td align="center">'.$d.'</td>'.
                '<td align="center">'.util::convertTime($t).'</td>'.
                '<td align="center">'.$p->{'duration'}.'</td>'.
                '<td align="center">'.$p->{'station'}.'</td>'.
                '<td>'.$p->{'title'}.'</td>'.
                '<td>'.$p->{'subtitle'}.'</td>'.
                '</tr>';
    
            $counter++;
        }
    }
    
    print '</table>';
    
    print '<p>';
    
    my $cmd = 'df -h '.db::getPref('recording_dir');
    
    my ($line1, $line2) = split(/\n/, `$cmd`);
    
    my @parts = split(/\s+/, $line2);
    
    print "$parts[2] of $parts[1] ($parts[4]) used<p>";

}

footer::print();
