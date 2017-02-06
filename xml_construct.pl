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

quiz_validate($dom);

#extra validation against schema
my $quiz = $dom->findnodes('/quiz')->shift();
my $header = $quiz->findnodes('./header')->shift();
my $tossups = $header->findnodes('./toss_ups')->shift()->textContent;
my @tus = $quiz->findnodes('./toss_up');
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

$acc = 1;
my $bps;
if ($header->exists('./boni_per_set')){
	$bps = $header->findnodes('./boni_per_set')->shift()->textContent;
}
my @bps = $quiz->findnodes('./bonus_set');
foreach(@bs){
	if ($_->exists('./boni_in_set')){
		$bps = $_->findnodes('./boni_in_set')->shift()->textContent;
	} elsif (defined $bps) {
	} else {
		my $b_p_s = $_->findnodes('./number')->shift()->textContent;
		die "No boni-per-set defined for bonus set $b_p_s";
	}
}


