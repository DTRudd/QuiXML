#!/usr/bin/perl
package QuiXML::Text;

use warnings;
use strict;
use v5.20;
use parent QuiXML::TUQAtom;

sub new{
	my $class = shift;
	my $text = shift;

	my $self = {};
	bless($self,$class);
	$self->{text} = $text;
	return $self;
}

sub text{
	my $self = shift;
	if (@_){
		$self->{text} = shift;
	}
	return $self->{text};
}

sub write{
	my $self = shift;
	return $self->text;
}
