#!/usr/bin/perl

#
# This program should run as a cron job every minute.  It checks the
# queue.dat file and starts a recording on an open tuner.  If the recording
# comes to an end, then it removes the item from the queue and places it
# in the recorded.dat file.
#

use lib '../lib';
use strict;
use config;
use db;
use Date::Calc qw(Add_Delta_YMDHMS Mktime);
use hdhr;
use logger;

sub main {

    db::init();

    my $programs = db::getQueue();

    my $now = time();
    
    my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime($now);

    $year += 1900;
    $month++;

    # Clear any finished recordings from the queue and move to the
    # recorded table

    foreach my $p (@{$programs}) {

        if (length($p->{'tuner'})) {

            if ($p->{'time'} =~ /(.*)\-(.*)\-(.*) (.*)\:(.*)/) {

                my ($dh, $dm) = split(/\:/, $p->{'duration'});

                my ($ny, $nm, $nd, $nh, $nn, $ns) =
                    Add_Delta_YMDHMS($1, $2, $3, $4, $5, 0,
                        0, 0, 0, $dh, $dm, 0);
                    
                my $t1 = Mktime($ny, $nm, $nd, $nh, $nn, $ns);
                
                if ($now > $t1) {
                    logger::log("$p->{'time'} - $p->{'title'} finished");
                    hdhr::clear($p->{'tuner'});
                    db::markRecorded($p->{'tuner'});
                }
            }
        }
    }

    # Start a recording

    foreach my $p (@{$programs}) {

        if ($p->{'time'} =~ /(.*)\-(.*)\-(.*) (.*)\:(.*)/) {

            if (($year >= $1) and ($month >= $2) and ($day >= $3) and
                ($hour >= $4) and ($min >= $5)) {
                if (!length($p->{tuner})) {
                    record($p);
                }
            }
        }
    }
}

sub record {

    my $p = shift;

    my $tuner_rec = db::getTunerRec($p->{station});

    my $directory = db::getPref('recording_dir').'/'.$p->{'title'};
    $directory =~ s/ /_/g;
    $directory =~ s/\:/_/g;
    $directory =~ s/\-/_/g;
    $directory =~ s/\'//g;
    $directory =~ s/\!//g;
    
    my $filename .= $p->{'time'}.'.mpg';   
    $filename =~ s/ /_/g;
    $filename =~ s/\:/_/g;
    $filename =~ s/\-/_/g;
    $filename =~ s/\'//g;
    $filename =~ s/\!//g;
                
    my $tuner = hdhr::record($tuner_rec->{'channel'}, $tuner_rec->{'program'}, $directory, $filename);

    logger::log("$p->{'time'} - $p->{'title'} on Tuner $tuner");

    db::updateQueue($p->{queue_id}, $tuner);
}

main();
