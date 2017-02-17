#!/usr/bin/perl
package QuiXML::Power;

use warnings;
use strict;
use v5.20;
use parent QuiXML::TUQAtom;

sub new{
	my $class = shift;
	my $points = shift;

	my $self = {};
	bless($self,$class);
	$self->{points} = $points;
	return $self;
}

sub points{
	my $self = shift;
	if (@_){
		$self->{points} = shift;
	}
	return $self->{points};
}

sub write{
	my $self = shift;
	my $points = $self->points;
	return "\[\\textbf\{$points\}p\]";
}
