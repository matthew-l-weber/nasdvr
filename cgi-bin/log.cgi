#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use header;
use footer;
use db;


db::init();

print CGI::header();

header::print();

print '<h2>Log</h2>';

open(inFile, '<',db::getPref('log_file'));
while (<inFile>) {
    print "$_<br>"
}
close (inFile);

footer::print();

