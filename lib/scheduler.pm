package scheduler;

use strict;
use db;
use config;

sub unscheduleFavorites {
 
    my $favorites = db::getFavorites();
    
    foreach my $p (@{$favorites}) {
        db::cancelSeries($p->{program_id}, $p->{station_id});
    }
}

sub scheduleFavorites {

    unscheduleFavorites();
    
    my $favorites = db::getFavorites();
    
    foreach my $p (@{$favorites}) {
        
        my $schedule = db::getSeries(
            $p->{program_id}, $p->{station_id});
        
        foreach my $s (@{$schedule}) {
            db::queue($s->{schedule_id});
        }
    }    
}

return 1;
