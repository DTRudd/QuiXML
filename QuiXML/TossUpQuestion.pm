#!/usr/bin/perl
package QuiXML::TossUpQuestion;

use warnings;
use strict;
use v5.20;
use QuiXML::Instructions;

sub new{
	#attributes;
	my $class = shift;
	my $instructions = shift;
	my $text = shift; #array ref of text blocks and neg/power tags

	my $self = {};
	bless($self,$class);
	$self->{instructions} = $instructions;
	$self->{text} = $text;
	return $self;
}

sub instructions{
	my $self = shift;
	if (@_){
		$self->{instructions} = shift;
	}
	return $self->{instructions};
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
	$outp = join("\n",$outp,$self->instructions->write);
	my $text = $self->text;
	my @text = @$text;
	foreach(@text){
		
	}
	$outp = join('  ',$outp,"\\newline");
	return $outp;
}
