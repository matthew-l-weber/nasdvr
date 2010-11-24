#!/usr/bin/perl

use strict;
use lib '../lib';
use config;
use sd;
use db;
use scheduler;

db::init();
sd::update();
scheduler::scheduleFavorites();

