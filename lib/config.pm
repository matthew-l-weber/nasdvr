package config;

use strict;

my %vals;

$vals{db_name} = 'nasdvr';
$vals{db_host} = '192.168.3.10';
$vals{db_username} = 'admin';
$vals{db_password} = 'password';

sub getValue {
    my $key = shift;
    return $vals{$key};
}

return 1;
