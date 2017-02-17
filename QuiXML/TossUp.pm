#!/usr/bin/perl
package QuiXML::TossUp;

use warnings;
use strict;
use v5.20;
use QuiXML::Answer;
use QuiXML::TossUpQuestion;
use parent QuiXML::Writeable;

sub new{
	#attributes;
	my $class = shift;
	my $number = shift;
	my $points = shift;
	my $is_points_unique = shift;
	my $question = shift;
	my $answer = shift;

	my $self = {};
	bless($self,$class);
	$self->{number} = $number;
	$self->{points} = $points;
	$self->{is_points_unique} = $is_points_unique;
	$self->{question} = $question;
	$self->{answer} = $answer;
	return $self;
}

sub number{
	my $self = shift;
	if (@_){
		$self->{number} = shift;
	}
	return $self->{number};
}

sub points{
	my $self = shift;
	if (@_){
		$self->{points} = shift;
	}
	return $self->{points};
}

sub is_points_unique{
	my $self = shift;
	if (@_){
		$self->{is_points_unique} = shift;
	}
	return $self->{is_points_unique};
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
	my $num = $self->number;
	$outp = join("\n",$outp,"\\subsection*\{\\textbf\{$num.\}\}");
	if($self->is_points_unique){
		my $points = $self->points;
		$outp = join('',$outp,"\\textit\{This toss-up is worth \\textbf\{$points_txt\} points.\}\\newline");
	}
	$outp = join("\n",$outp,$self->$question->write);
	$outp = join("\n",$outp,$self->$answer->write);
	return $outp;
}
