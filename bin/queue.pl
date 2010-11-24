#!/usr/bin/perl

use strict;
use lib '../lib';
use config;
use sd;
use db;

db::init();

db::queue(517);

