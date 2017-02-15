#!/usr/bin/perl
package QuiXML::Instructions;

use warnings;
use strict;
use v5.20;

sub new{
	#attributes;
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
	my $outp = '';
	$outp = join("\n",$outp,$self->text);
	return $outp;
}

