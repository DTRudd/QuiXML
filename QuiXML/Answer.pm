#!/usr/bin/perl
package QuiXML::Answer;

use warnings;
use strict;
use v5.20;
use QuiXML::Instructions;

sub new{
	#attributes;
	my $class = shift;
	my $instructions = shift;
	my $answerList = shift;

	my $self = {};
	bless($self,$class);
	$self->{instructions} = $instructions;
	$self->{answerList} = $answerList;
	return $self;
}

sub instructions{
	my $self = shift;
	if (@_){
		$self->{instructions} = shift;
	}
	return $self->{instructions};
}

sub answerList{
	my $self = shift;
	if (@_){
		$self->{answerList} = shift;
	}
	return $self->{answerList};
}

sub write{
	my $self = shift;
	my $outp = '';
	$outp = join("\n",$outp,$self->instructions->write,'ANSWER:');
	my $answerList = $self->{answerList};
	my @answerList = @$answerList;
	foreach(@answerList){
		$outp = join('',$outp,"\\textbf\{$_\}");
		if ($_ == @answerList[-1]){
			$outp = join('',$outp,'.');
		} else {
			$outp = join('',$outp,',');
		}
	}
	return $outp;
}

