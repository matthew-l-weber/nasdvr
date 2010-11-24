#!/usr/bin/perl

use CGI;
use strict;
use lib '../lib';
use db;
use header;
use footer;
use config;

db::init();

my $names = db::getPrefNames();

if (CGI::param('action') eq 'save') {
	save();
	print CGI::redirect(-url => 'configure.cgi');
} else {
	print CGI::header();
}

header::print();

print '<h2>Configure</h2>';

print '<form method="post">';
print '<input type="hidden" name="action" value="save">';

print '<table cellpadding="5" cellspacing="0">';

foreach my $k (@{$names}) {

    print '<tr><td><b>'.$k.':</b></td><td>
        <input size="50" name="'.$k.'" value="'.
        db::getPref($k).'"></td></tr>';
}

print '</table><p>';

print '<input type="submit" value="Save">';

print '</form>';

footer::print();

sub save {

	foreach my $name (@{$names}) {
	    db::setPref($name, CGI::param($name));
	}
}

