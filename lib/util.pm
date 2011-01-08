package util;

sub convertTime {
 
    my $t = shift;
    
    my ($hour, $min) = split(/:/, $t);
    my $suffix = 'AM';
    
    if ($hour > 11) {
        $suffix = 'PM';
    }

    if ($hour > 12) {
        $hour -= 12;
    }
    
    if ($hour == 0) {
        $hour = 12;
    }
    
    $t = sprintf("%02d:%02d %s", $hour, $min, $suffix);

    return $t;
}

return 1;

