#!perl
#
# Quick sample script to fetch data from Tribune's Data Direct Service
#
# R. Eden 2/23/08
# (modified from XMLTV's tv_grab_na_dd, which started with a sample)
# script provided by Tribune

use SOAP::Lite;
use strict;

my $USER='adam@sycamore.us';
my $PASS='3edc4rfv';
my $START='2010-11-18T04:00:00Z';
my $STOP ='2010-11-19T03:59:59Z';

#
# Set login credientials
# 
sub SOAP::Transport::HTTP::Client::get_basic_credentials {
    return lc($USER) => "$PASS";
}


#
# Deifne SOAP service
#
my $dd_service='http://docs.tms.tribune.com/tech/tmsdatadirect/schedulesdirect/tvDataDelivery.wsdl';
my $proxy='http://localhost/';
my $soap= SOAP::Lite
        -> service($dd_service)
        -> outputxml('true')
        -> proxy($proxy, options => {compress_threshold => 10000,
                                     timeout            => 420});

#
# It's polite to set an agent string
#
$soap->transport->agent("perl/$0");


#
# Now let's get our data
#
my $raw_data=$soap->download($START,$STOP);


print $raw_data;
exit 0;