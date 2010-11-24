package logger;

use strict;
use config;

sub log {

    my $msg = shift;

    open(FILE, ">>".db::getPref('log_file'));
    print FILE "$msg\n";
    close(FILE);
}

return 1;
