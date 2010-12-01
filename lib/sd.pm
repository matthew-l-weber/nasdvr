package sd;

use config;
use db;
use SOAP::Lite;
use strict;
use XML::Twig;
use Date::Calc qw(Add_Delta_YMDHMS);
use logger;

my %station_hash;
my %program_hash;

sub SOAP::Transport::HTTP::Client::get_basic_credentials {
    return db::getPref('sd_username') => db::getPref('sd_password');
}

sub update {

    db::clearStationMap();
    db::clearSchedule();
    db::clearPrograms();

    my $url = db::getPref('sd_url');

    my $soap = SOAP::Lite->service($url)->outputxml('true');

    my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = 
		localtime(time);
    
    $year += 1900;

    my $root_path = 'SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:downloadResponse/xtvdResponse/xtvd';
    my $station_path = $root_path.'/lineups/lineup/map';
    my $schedule_path = $root_path.'/schedules/schedule';
    my $program_path = $root_path.'/programs/program';

    my $twig = XML::Twig->new(twig_handlers => {
        $station_path, \&handleStationMap,
        $schedule_path, \&handleSchedule,
        $program_path, \&handleProgram
    });

    for (my $i = 0; $i < db::getPref('sd_num_days'); $i++) {

        my ($y, $m, $d, $h, $n, $s) = Add_Delta_YMDHMS(
			$year, $month, $day,
			0, 0, 0, 
			0, 0, $i, db::getPref('tz_offset'), 0, 0);

        my $start = sprintf("%04d-%02d-%02dT%02d:00:00Z", 
			$y, $m + 1, $d, $h);
		
        my ($y, $m, $d, $h, $n, $s) = Add_Delta_YMDHMS(
			$year, $month, $day,
			0, 0, 0, 
			0, 0, $i, db::getPref('tz_offset') + 23, 59, 59);

        my $stop = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", 
			$y, $m + 1, $d, $h, $n, $s);

        logger::log("Updating schedule from $start to $stop");

        my $data = $soap->download($start, $stop);

        $twig->parse($data);
    }
}

sub handleStationMap {

    my $twig = shift;
    my $station = shift;

    if (!defined($station_hash{$station->att('station')})) {
        db::addStationMap(
        $station->att('station'),
        $station->att('channel'),
        $station->att('channelMinor'));
    }

    $station_hash{$station->att('station')} = 1;

    $twig->purge;
}

sub handleSchedule {

    my $twig = shift;
    my $schedule = shift;

    db::addSchedule(
    $schedule->att('program'),
    $schedule->att('station'),
    $schedule->att('time'),
    $schedule->att('duration'));

    $twig->purge;
}

sub handleProgram {

    my $twig = shift;
    my $program = shift;

    if (!defined($program_hash{$program->att('id')})) {
        db::addProgram(
        $program->att('id'),
        $program->first_child('title')->text,
        defined($program->first_child('subtitle')) ? $program->first_child('subtitle')->text : '',
        defined($program->first_child('description')) ? $program->first_child('description')->text : '');
    }

    $program_hash{$program->att('id')} = 1;

    $twig->purge;
}

return 1;
