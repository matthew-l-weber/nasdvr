package db;

use lib '/usr/lib/perl5/vendor_perl/5.8.8/armv5tejl-linux';
use strict;
use config;
use Date::Calc qw(Add_Delta_YMDHMS Mktime);
use DBI;
use logger;
use util;

my $db;

sub init {

    if (!defined($db)) {
        $db = DBI->connect('dbi:mysql:database='.
            config::getValue('db_name').';host='.
            config::getValue('db_host'),
        config::getValue('db_username'),
        config::getValue('db_password'));
    }
}

sub clearStationMap {

    $db->do('delete from stations where station_id not in 
        (select station_id from queue) and station_id not in
        (select station_id from recorded)');
}

sub clearSchedule {

    $db->do('delete from schedule');
}

sub clearPrograms {

    $db->do('delete from programs where program_id not in 
        (select program_id from queue) and program_id not in
        (select program_id from recorded) and program_id not in
        (select program_id from favorites)');
}

sub clearTunerTable {

    $db->do('delete from tuners');
}

sub addStationMap {

    my $station_id = shift;
    my $channel = shift;
    my $minor = shift;

    my $rec = getStationRec($station_id);
    
    if (!defined($rec)) {
        
        my $st = $db->prepare('insert into stations
        (station_id, channel, minor) values
        (?, ?, ?)');
        
        $st->execute($station_id, $channel, $minor);
    }
}

sub addSchedule {

    my $program_id = shift;
    my $station = shift;
    my $time = shift;
    my $duration = shift;

    $time = convertTime($time);
    
    my $st = $db->prepare('insert into schedule
    (program_id, station_id, start_time, duration) values
    (?, ?, ?, ?)');

    $st->execute($program_id, $station, $time, $duration);
}

sub addProgram {

    my $program_id = shift;
    my $title = shift;
    my $subtitle = shift;
    my $desc = shift;
    
    my $rec = getProgramRec($program_id);
    
    if (!defined($rec)) {

        my $st = $db->prepare('insert into programs
        (program_id, title, subtitle, description) values
        (?, ?, ?, ?)');
    
        $st->execute($program_id, $title, $subtitle, $desc);
    }
}

sub addTunerRec {

    my $tuner = shift;
    my $channel = shift;
    my $program = shift;
    my $number = shift;
    my $name = shift;

    my $st = $db->prepare('insert into tuners
    (tuner, channel, program, number, name) values
    (?, ?, ?, ?, ?)');

    $st->execute($tuner, $channel, $program, $number, $name);
}

sub getPrograms {

    my $day = shift;
    my $start = shift;
    my $stop = shift;
    my $station = shift;

    my @programs;

    if (!defined($start)) {
        $start = $day.'T00:00Z';
    } else {
       $start = $day.'T'.$start.'Z';
    }

    if (!defined($stop)) {
        $stop = $day.'T24:00Z';
    } else {
        $stop = $day.'T'.$stop.'Z';
    }

    my $st = $db->prepare('select schedule.*, programs.*, stations.* from schedule
        left outer join programs on (schedule.program_id = programs.program_id)
        left outer join stations on (schedule.station_id = stations.station_id)
        where start_time like ? and start_time >= ? and start_time <= ?
        order by start_time, stations.channel, stations.minor');

    $st->execute($day.'%', $start, $stop);

    while (my $rec = $st->fetchrow_hashref()) {
        
        $rec->{duration} = substr($rec->{duration}, 2, 2).':'.
            substr($rec->{duration}, 5, 2);
        $rec->{station} = $rec->{channel}.'.'.$rec->{minor};
        $rec->{time} = substr($rec->{start_time}, 11, 5);

        if (!defined($station) or
            ($station eq '') or
            ($station eq $rec->{station})) {
            push @programs, $rec;
        }
    }

    return \@programs;
}

sub getSearch {

    my $query = shift;

    my @programs;
    
    if (length($query)) {

        my $st = $db->prepare('select schedule.*, programs.*, stations.* from schedule
            left outer join programs on (schedule.program_id = programs.program_id)
            left outer join stations on (schedule.station_id = stations.station_id)
            where (upper(programs.title) like ?) or
            (upper(programs.subtitle) like ?)
            order by start_time, stations.channel, stations.minor');
    
        $st->execute('%'.uc($query).'%', '%'.uc($query).'%');
    
        while (my $rec = $st->fetchrow_hashref()) {
            
            $rec->{duration} = substr($rec->{duration}, 2, 2).':'.
                substr($rec->{duration}, 5, 2);
            $rec->{station} = $rec->{channel}.'.'.$rec->{minor};
            $rec->{time} = substr($rec->{start_time}, 0, 10).' '.
                substr($rec->{start_time}, 11, 5);
    
            push @programs, $rec;
        }
    }
    
    return \@programs;
}

sub getProgramRec {

    my $id = shift;

    my $st = $db->prepare('select * from programs where program_id = ?');

    $st->execute($id);

    my $rec = $st->fetchrow_hashref();

    return $rec;
}

sub getRecordedRec {

    my $id = shift;

    my $st = $db->prepare('select * from recorded where record_id = ?');

    $st->execute($id);

    my $rec = $st->fetchrow_hashref();

    my $time = substr($rec->{start_time}, 0, 10).' '.
            substr($rec->{start_time}, 11, 5);

    my $program_rec = getProgramRec($rec->{program_id});

    my $filename = util::cleanFilename($program_rec->{'title'}.'/'.$time.'.mpg');
    
    $rec->{filename} = $filename;
    
    return $rec;
}

sub getStations {

    my $st = $db->prepare('select * from stations order by channel, minor');

    $st->execute();

    my @stations;

    while (my $rec = $st->fetchrow_hashref()) {
        push @stations, "$rec->{channel}.$rec->{minor}";
    }

    return \@stations;
}

sub convertTime {

    my $time = shift;

    if ($time =~ /(.*)\-(.*)\-(.*)T(.*)\:(.*)\:(.*)Z/) {

        my ($y, $m, $d, $h, $n, $s) = Add_Delta_YMDHMS(
        $1, $2, $3, $4, $5, $6,
        0, 0, 0, getPref('tz_offset') * -1, 0, 0);

        $time = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
        $y, $m, $d, $h, $n, $s);
    }

    return $time;
}

sub markRecorded {

    my $tuner = shift;

    my $st= $db->prepare('select * from queue where tuner = ?');

    $st->execute($tuner);

    my $rec = $st->fetchrow_hashref();

    my $st3 = $db->prepare('insert into recorded (program_id, station_id,
        start_time, duration) values (?, ?, ?, ?)');

    $st3->execute($rec->{program_id}, $rec->{station_id},
        $rec->{start_time}, $rec->{duration});

    my $st4 = $db->prepare('delete from queue where queue_id = ?');

    $st4->execute($rec->{queue_id});
}

sub updateQueue {

    my $index = shift;
    my $tuner = shift;

    my $st = $db->prepare('update queue set tuner = ? where queue_id = ?');

    $st->execute($tuner, $index);
}

sub getQueue {

    my $st = $db->prepare('select queue.*, programs.*, stations.* from queue
        left outer join programs on (queue.program_id = programs.program_id)
        left outer join stations on (queue.station_id = stations.station_id)
        order by queue.start_time');

    $st->execute();
    
    my @programs;

    while (my $rec = $st->fetchrow_hashref()) {

        $rec->{duration} = substr($rec->{duration}, 2, 2).':'.
            substr($rec->{duration}, 5, 2);

        $rec->{station} = $rec->{channel}.'.'.$rec->{minor};

        $rec->{time} = substr($rec->{start_time}, 0, 10).' '.
            substr($rec->{start_time}, 11, 5);

        push @programs, $rec;
    }

    return \@programs;
}

sub getRecorded {

    my @programs;

    my $st = $db->prepare('select recorded.*, programs.*, stations.* from recorded
        left outer join programs on (recorded.program_id = programs.program_id)
        left outer join stations on (recorded.station_id = stations.station_id)
        where recorded.deleted != 1 order by start_time desc');

    $st->execute();

    while (my $rec = $st->fetchrow_hashref()) {

        $rec->{duration} = substr($rec->{duration}, 2, 2).':'.
            substr($rec->{duration}, 5, 2);

        $rec->{station} = $rec->{channel}.'.'.$rec->{minor};

        $rec->{time} = substr($rec->{start_time}, 0, 10).' '.
            substr($rec->{start_time}, 11, 5);

        my $time = substr($rec->{start_time}, 0, 10).' '.
                substr($rec->{start_time}, 11, 5);
    
        my $program_rec = getProgramRec($rec->{program_id});
    
        my $filename = util::cleanFilename($program_rec->{'title'}.'/'.$time.'.mpg');
        
        $rec->{filename} = $filename;
    
        push @programs, $rec;
    }

    return \@programs;
}

sub getTuners {

    my $st = $db->prepare('select * from tuners order by tuner, channel, program');

    $st->execute();

    my @tuners;

    while (my $rec = $st->fetchrow_hashref()) {
        push @tuners, $rec;
    }

    return \@tuners;
}

sub getTunerRec {

    my $number = shift;

    my $st = $db->prepare('select * from tuners where number = ?');

    $st->execute($number);

    my $rec = $st->fetchrow_hashref();

    return $rec;
}

sub getStationRec {

    my $station_id = shift;

    my $st = $db->prepare('select * from stations where station_id = ?');

    $st->execute($station_id);

    my $rec = $st->fetchrow_hashref();

    if (defined($rec)) {
        $rec->{number} = $rec->{channel}.'.'.$rec->{minor};
    }

    return $rec;
}

sub getScheduleRec {

    my $schedule_id = shift;

    my $st = $db->prepare('select * from schedule where schedule_id = ?');

    $st->execute($schedule_id);

    my $rec = $st->fetchrow_hashref();

    $rec->{time} = substr($rec->{start_time}, 0, 10).' '.
        substr($rec->{start_time}, 11, 5);

    return $rec;
}

sub getQueueRec {

    my $id = shift;

    my $st = $db->prepare('select * from queue where queue_id = ?');

    $st->execute($id);

    my $rec = $st->fetchrow_hashref();

    return $rec;
}

sub queue {

    my $id = shift;    
    
    my $rec = getScheduleRec($id);

    my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime(time);

    $year += 1900;
    $month++;

    if ($rec->{start_time} =~ /(.*)\-(.*)\-(.*)T(.*)\:(.*)\:(.*)Z/) {

		# Only record shows that are not in the queue and 
		# are not recorded already
		
		my $st = $db->prepare('select * from queue where program_id = ?');
		$st->execute($rec->{program_id});
		my $rec2 = $st->fetchrow_hashref();
		
		my $st = $db->prepare('select * from recorded where program_id = ?');
		$st->execute($rec->{program_id});
		my $rec3 = $st->fetchrow_hashref();
		
		if (!defined($rec2) and !defined($rec3)) {
			my $st = $db->prepare('insert into queue (program_id, station_id,
				start_time, duration) values (?, ?, ?, ?)');        
			$st->execute($rec->{program_id}, $rec->{station_id}, 
					$rec->{start_time}, $rec->{duration});
		}
    }
}

sub cancel {

    my $id = shift;

    my $st = $db->prepare('delete from queue where queue_id = ?');

    $st->execute($id);
 }

sub deleteRecording {

    my $id = shift;

    my $st = $db->prepare('select * from recorded where record_id = ?');

    $st->execute($id);

    my $rec = $st->fetchrow_hashref();

    my $time = substr($rec->{start_time}, 0, 10).' '.
            substr($rec->{start_time}, 11, 5);

    my $program_rec = getProgramRec($rec->{program_id});

    my $filename = $time.'_'.$program_rec->{'title'};
    $filename =~ s/ /_/g;
    $filename =~ s/\:/_/g;
    $filename =~ s/\-/_/g;
    $filename =~ s/\'//g;
    $filename =~ s/\!//g;
    $filename .= '.mpg';

    if ( -f getPref('recording_dir').'/'.$filename) {
        unlink(getPref('recording_dir').'/'.$filename);
        logger::log("$filename deleted");
    }
    
    $st = $db->prepare('update recorded set deleted = ? where record_id = ?');

    $st->execute(1, $id) or logger::log("$DBI::errstr");
}

sub getPref {
    
    my $name = shift;
    
    my $st = $db->prepare('select * from prefs where name = ?');
    
    $st->execute($name);
    
    my $rec = $st->fetchrow_hashref();
    
    return $rec->{value};
}

sub setPref {
 
    my $name = shift;
    my $value = shift;
    
    my $st = $db->prepare('select * from prefs where name = ?');
    
    $st->execute($name);
    
    my $rec = $st->fetchrow_hashref();

    if (defined($rec)) {
        my $st = $db->prepare('update prefs set value = ? where name = ?');    
        $st->execute($value, $name);
    } else {
        my $st = $db->prepare('insert into prefs (name, value) values (?, ?)');    
        $st->execute($name, $value);
    }
}

sub getPrefNames {
    
    my $st = $db->prepare('select * from prefs order by name');
    
    $st->execute();
    
    my @names;
    
    while (my $rec = $st->fetchrow_hashref()) {
        push @names, $rec->{name};
    }
    
    return \@names;
}

sub getFavorites {
    
    my @programs;
    
    my $st = $db->prepare('select favorites.*, programs.*, stations.* from favorites
        left outer join programs on (favorites.program_id = programs.program_id)
        left outer join stations on (favorites.station_id = stations.station_id)
        order by stations.channel, stations.minor, programs.title');

    $st->execute();

    while (my $rec = $st->fetchrow_hashref()) {
        $rec->{station} = $rec->{channel}.'.'.$rec->{minor};
        push @programs, $rec;
    }

    return \@programs;
}

sub addFavorite {
    
    my $schedule_id = shift;
    
    my $rec = getScheduleRec($schedule_id);
    
    my $st = $db->prepare('insert into favorites
        (program_id, station_id) values (?, ?)');

    $st->execute($rec->{program_id}, $rec->{station_id});
}

sub deleteFavorite {

    my $favorite_id = shift;
    
    my $st = $db->prepare('delete from favorites where favorite_id = ?');

    $st->execute($favorite_id);
}

sub getSeries {
    
    my $program_id = shift;
    my $station_id = shift;
    
    my $program_id = substr($program_id, 2, 8);

    my $st = $db->prepare('select * from schedule where program_id like ? and 
        station_id = ?');
    
    $st->execute('%'.$program_id.'%', $station_id);
 
    my @programs;
    
    while (my $rec = $st->fetchrow_hashref()) {
        push @programs, $rec;
    }
    
    return \@programs;
}

sub cancelSeries {
    
    my $program_id = shift;
    my $station_id = shift;
    
    my $program_id = substr($program_id, 2, 8);
        
    my $st = $db->prepare('delete from queue where program_id like ? and 
        station_id = ?');
    
    $st->execute('%'.$program_id.'%', $station_id);
}

return 1;

