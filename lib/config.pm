package config;

use strict;

my %vals;

$vals{db_name} = 'nasdvr';
$vals{db_username} = 'root';
$vals{db_password} = 'root';

sub getValue {
    my $key = shift;
    return $vals{$key};
}

return 1;
