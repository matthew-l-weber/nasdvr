#!/usr/bin/perl

use strict;
use lib '../lib';
use hdhr;
use db;

db::init();

if ($ARGV[0] eq 'scan') {
    hdhr::scan();
} elsif ($ARGV[0] eq 'record') {
	print hdhr::record($ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
} elsif ($ARGV[0] eq 'clear') {
	print hdhr::clear($ARGV[1]);
}

print "\n";
