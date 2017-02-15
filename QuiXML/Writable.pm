#!/usr/bin/perl
package QuiXML::Writable;

use warnings;
use strict;
use v5.20;

sub new{
	my $class = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}

sub write{
	return "";
}
