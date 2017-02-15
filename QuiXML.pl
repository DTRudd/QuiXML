#!/usr/bin/perl
use warnings;
use strict;
use v5.20;
use lib '/home/sophie/qbowl';
use QuiXML::Validate;

my $input = '';
while (<ARGV>){
	$input = join('',$input,"$_\n");
}
quiz_validate($input);
