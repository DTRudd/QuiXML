#!/usr/bin/perl
use warnings;
use strict;
use v5.20;
use XML::LibXML;

#subroutine to validate file against quiz schema
sub quiz_validate{
	my ($input) = @_;
	my $schema = XML::LibXML::Schema->new( location => 'quiz.xsd' );
	eval {$schema->validate($input);};
	if ($@) {
		die "XML input is invalid with schema:\n$@";
	}
}

my $parser = XML::LibXML->new();
my $file = "";
while (<ARGV>){
	$file = join('',$file,"$_\n");
}
my $dom = $parser->parse_string($file) or die 'Cannot read file.';

#validate it against schema
quiz_validate($dom);

my @tossups = $dom->findnodes('/quiz/header/toss_ups');
my $tossups = $tossups[0]->textContent;
my @tus = $dom->findnodes('/quiz/toss_up/number');
my $acc = 1;
foreach(@tus){
	my $tunum = $_->textContent;
	die "Toss-up $tunum is incorrectly numbered" if $tunum != $acc;
	die "Too many toss-ups" if $tunum > $tossups;
	$acc++;
}
die "Not enough toss-ups" if $acc < $tossups;

my @bonussets = $dom->findnodes('/quiz/header/bonus_sets');
my $bonussets = $bonussets[0]->textContent;
my @bs = $dom->findnodes('/quiz/bonus_set/number');
$acc = 1;
foreach(@bs){
	my $bsnum = $_->textContent;
	die "Bonus set $bsnum is incorrectly numbered" if $bsnum != $acc;
	die "Too many bonus sets" if $bsnum > $bonussets;
	$acc++;
}
die "Not enough bonus sets" if $acc < $bonussets;

$acc = 1;

my @bps = $dom->findnodes('/quiz/header/boni_per_set');
my $bps = $bps[0]->textContent ;

my @bis = $dom->findnodes('/quiz/bonus_set/boni_in_set');
