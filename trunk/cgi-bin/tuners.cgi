#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use header;
use footer;
use config;

db::init();

print CGI::header();

my $results;

if (CGI::param('action') eq 'scan') {
	my $cmd = 'cd '.db::getPref('root_dir').'/bin; perl ./hdhr.pl scan';
	`$cmd`;
	$results = 'Tuner scan complete';
} elsif (CGI::param('action') eq 'discover') {
	my $cmd = db::getPref('hdhr_config').' discover';
	$results = `$cmd`;
}

header::print();

print '<h2>Tuners</h2>';

if (defined($results)) {
	print "$results<p>";
}

print '<form name="tuner_form">';
print '<input type="hidden" name="action" value="scan">';
print '<input type="button" value="Discover" onclick="document.tuner_form.action.value=\'discover\';submit();">&nbsp;';
print '<input type="submit" value="Scan" onclick="return confirm(\'This make take a while\')"><p></form>';

print '<table cellpadding="5" cellspacing="0">';

print '<tr bgcolor="#cccccc"><th>Tuner</th><th>Channel</th>
    <th>Program</th><th>Number</th><th>Name</th></tr>';

my $tuners = db::getTuners();

my $counter = 0;

foreach my $t (@{$tuners}) {

    my $color = ($counter % 2) ? '#eeeeee' : '#ffffff';

    print '<tr align="center" bgcolor="'.$color.'">'.
        '<td>'.$t->{tuner}.'</td>'.
        '<td>'.$t->{channel}.'</td>'.
        '<td>'.$t->{program}.'</td>'.
        '<td>'.$t->{number}.'</td>'.
        '<td>'.$t->{name}.'</td>'.
        '</tr>';

    $counter++;
}

print '</table>';

footer::print();

