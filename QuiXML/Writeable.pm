#!/usr/bin/perl
package QuiXML::Writeable;

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
