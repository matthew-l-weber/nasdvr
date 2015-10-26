package hdhr;

use lib 'lib';
use strict;
use config;
use db;
use logger;

sub scan {

    db::clearTunerTable();

    my $hdhr_config = db::getPref('hdhr_config');
    my $hdhr_id = db::getPref('hdhr_id');

    for (my $i = 0; $i < 2; $i++) {

        my @lines = `$hdhr_config $hdhr_id scan /tuner$i`;

        my $channel;

        foreach my $l (@lines) {

            chop $l;

            if ($l =~ /^SCANNING.*:(.*)\)/) {
                $channel = $1;
            }

            if ($l =~ /^PROGRAM/) {

                my @parts = split(/ /, $l);
                my $program_id = $parts[1];
                my $program_number = $parts[2];
                my $program_name = $parts[3];

                $program_id =~ s/\://g;

                if ($program_number ne '0') {
                    db::addTunerRec($i, $channel,
                    $program_id, $program_number, $program_name);
                }
            }
        }
    }
}

sub reserve {

    my $channel = shift;
    my $program = shift;
    my $filename = shift;

    if (!defined($channel) or !defined($program) or !defined($filename)) {
	logger::log("record chan/prog/file arg error");
        return;
    }

    my $tuner;
    my $lockfile;
    my $lockfile0 = db::getPref('data_dir').'/tuner0.lock';
    my $lockfile1 = db::getPref('data_dir').'/tuner1.lock';

    if (! -f $lockfile0) {
        $tuner = 0;
        $lockfile = $lockfile0;
    } elsif (! -f $lockfile1) {
        $tuner = 1;
        $lockfile = $lockfile1;
    } else {
        # Invalid if no tuner
        return;
    }

    open(FILE, ">$lockfile");
    print FILE $$;
    logger::log("tuner$tuner: pid=$$");
    close(FILE);
    return $tuner;
}

sub record {

    my $channel = shift;
    my $program = shift;
    my $filename = shift;
    my $tuner = shift;

    my $hdhr_config = db::getPref('hdhr_config');
    my $hdhr_id = db::getPref('hdhr_id');

    if (defined($tuner)) {
        $filename = db::getPref('recording_dir').'/'.$filename;
        system("$hdhr_config $hdhr_id set /tuner$tuner/channel auto:$channel");
        system("$hdhr_config $hdhr_id set /tuner$tuner/program $program");
        system("$hdhr_config $hdhr_id save /tuner$tuner $filename");
        exit(0);
    }
    logger::log("record had invalid tuner");
}

sub clear {

    my $tuner = shift;

    my $hdhr_config = db::getPref('hdhr_config');
    my $hdhr_id = db::getPref('hdhr_id');

    my $lockfile = db::getPref('data_dir').'/tuner'.$tuner.'.lock';

    if (-f $lockfile) {

# Ignore pid in file as it's the script not the exec call process ID
#        open(FILE, $lockfile);
#        my $pid = <FILE>;
#        close(FILE);

        my $killStr = "ps aux | grep \"[s]ave /tuner$tuner\" |  awk \'NR==1{print \$2}\' ";
        my $pid=`$killStr`;
        my $call_output=`/bin/kill -9 \`$killStr\``;
        logger::log("tried to kill pid $pid for $tuner ERR[$call_output]");
        system("$hdhr_config $hdhr_id set /tuner$tuner/channel none");

        logger::log("tried to remove lock for $tuner");
        unlink($lockfile);
    }
}

return 1;
