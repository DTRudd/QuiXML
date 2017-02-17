#!/usr/bin/perl
package QuiXML::Bonus;

use warnings;
use strict;
use v5.20;
use QuiXML::Answer;
use QuiXML::BonusQuestion;
use parent QuiXML::Writeable;

sub new{
	#attributes;
	my $class = shift;
	my $points = shift;
	my $question = shift;
	my $answer = shift;

	my $self = {};
	bless($self,$class);
	$self->{points} = $points;
	$self->{question} = $question;
	$self->{answer} = $answer;
	return $self;
}

sub points{
	my $self = shift;
	if (@_){
		$self->{points} = shift;
	}
	return $self->{points};
}

sub question{
	my $self = shift;
	if (@_){
		$self->{question} = shift;
	}
	return $self->{question};
}

sub answer{
	my $self = shift;
	if (@_){
		$self->{answer} = shift;
	}
	return $self->{answer};
}

sub write{
	my $self = shift;
	my $outp = '';
	my $points = $self->points;
	$outp = join("\n",$outp,"\[\\textbf\{$points\}\]");
	$outp = join("\n",$outp,$self->question->write);
	$outp = join("\n",$outp,$self->answer->write);
	return $outp;
}
