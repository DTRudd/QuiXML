#!/usr/bin/perl
package QuiXML::BonusSet;

use warnings;
use strict;
use v5.20;
use QuiXML::Answer;
use QuiXML::Bonus;
use QuiXML::Instructions;

sub new{
	#attributes;
	my $class = shift;
	my $number = shift;
	my $instructions = shift;
	my $opener = shift;
	my $boni = shift;

	my $self = {};
	bless($self,$class);
	$self->{number} = $number;
	$self->{instructions} = $instructions;
	$self->{opener} = $opener;
	$self->{boni} = $boni;
	return $self;
}

sub number{
	my $self = shift;
	if (@_){
		$self->{number} = shift;
	}
	return $self->{number};
}

sub instructions{
	my $self = shift;
	if (@_){
		$self->{instructions} = shift;
	}
	return $self->{instructions};
}

sub opener{
	my $self = shift;
	if (@_){
		$self->{opener} = shift;
	}
	return $self->{opener};
}

sub boni{
	my $self = shift;
	if (@_){
		$self->{boni} = shift;
	}
	return $self->{boni};
}


sub write{
	my $self = shift;
	my $outp = '';
	my $num = $self->number;
	$outp = join("\n",$outp,"\\subsection*\{\\textbf\{$num.\}\}");
	$outp = join("\n",$outp,$self->instructions->write);
	$outp = join("\n",$outp,$self->opener);
	my $boni = $self->boni;
	my @boni = @$boni;
	foreach(@boni){
		$outp = join("\n",$outp,$_->write);
	}
	return $outp;
}
