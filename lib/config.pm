package config;

use strict;

my %vals;

$vals{db_name} = 'nasdvr';
$vals{db_username} = 'admin';
$vals{db_password} = 'password';
$vals{recording_url} = 'http://192.168.3.10:81/recordings';

sub getValue {
    my $key = shift;
    return $vals{$key};
}

return 1;
