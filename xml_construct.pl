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

#validate against schema
quiz_validate($dom);

#non-schema validation

#get quiz, header, toss-up and bonus-set locations
my $quiz = $dom->findnodes('/quiz')->shift();
my $header = $quiz->findnodes('./header')->shift();
my $tossups = $header->findnodes('./toss_ups')->shift()->textContent;
my @tus = $quiz->findnodes('./toss_up');

#validate toss-up numbers
my @tunums = @tus;
foreach(@tunums){
	$_ = $_->findnodes('./number')->shift()->textContent;
}
my $acc = 1;
foreach(@tunums){
	die "Toss-up $_ is incorrectly numbered" if $_ != $acc;
	die "Too many toss-ups" if $_ > $tossups;
	$acc++;
}
die "Not enough toss-ups" if $acc < $tossups;

say "Toss-ups numbered correctly.";

#validate bonus set numbers
my $bonussets = $header->findnodes('bonus_sets')->shift()->textContent;
my @bs = $quiz->findnodes('./bonus_set');
my @bsnums = @bs;
foreach(@bsnums){
	$_ = $_->findnodes('./number')->shift()->textContent;
}
$acc = 1;
foreach(@bsnums){
	die "Bonus set $_ is incorrectly numbered" if $_ != $acc;
	die "Too many bonus sets" if $_ > $bonussets;
	$acc++;
}
die "Not enough bonus sets" if $acc < $bonussets;

say "Bonus sets numbered correctly.";

#validate bonus numbers for each set
$acc = 1;
my $bps;
if ($header->exists('./boni_per_set')){
	$bps = $header->findnodes('./boni_per_set')->shift()->textContent;
	say "bpsx is $bps";
}
my @bps = $quiz->findnodes('./bonus_set');
my @bps_val = @bps;
foreach(@bs){
	if ($_->exists('./boni_in_set')){
		$bps_val[$acc-1] = $_->findnodes('./boni_in_set')->shift()->textContent;
	} elsif (defined $bps) {
		$bps_val[$acc-1] = $bps;
	} else {
		my $b_p_s = $_->findnodes('./number')->shift()->textContent;
		die "No boni-per-set defined for bonus set $b_p_s";
	}
	$acc++;
}
foreach(@bs){
	$acc = 1;
	my $bsnum = $_->findnodes('./number')->shift()->textContent;
	my @boni = $_->findnodes('./bonus/number');
	foreach (@boni){
		$_ = $_->textContent;
		die "Bonus question $_ in set $bsnum is incorrectly numbered" if $_ != $acc;
		die "Too many bonus questions in set $bsnum" if $_ > $bps_val[$bsnum-1];
		$acc++;
	}
	die "Not enough bonus questions in set $bsnum" if $acc < $bps_val[$bsnum-1];
}

say "Bonus questions numbered correctly.";
