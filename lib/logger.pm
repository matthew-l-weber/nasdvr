package logger;

use strict;
use config;

my ($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime(time);
$year += 1900;
$month++;
my $now_day = sprintf("%04d-%02d-%02d.%02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);

sub log {

    my $msg = shift;

    open(FILE, ">>".db::getPref('log_file'));
    print FILE "$now_day -> $msg\n";
    close(FILE);
}

return 1;
