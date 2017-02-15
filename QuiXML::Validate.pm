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

#validate toss-up numbers
my $tossups = $header->findnodes('./toss_ups')->shift()->textContent;
if ($tossups != 0){
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

	#validate points, powers and negs
	my $neg_points;
	my $tu_points;

	if ($header->exists('./neg_points')){
		$neg_points = $header->findnodes('./neg_points')->shift()->textContent;
	}
	if ($header->exists('./tu_points')){
		$tu_points = $header->findnodes('./tu_points')->shift()->textContent;
	}
	$acc = 1;
	foreach (@tus){
		if (!($_->exists('./points') or defined $tu_points)){
			die "Points not defined for question $acc";
		}
		my $text = $_->findnodes('./question/text')->shift();
		my @tchildren = $text->childNodes();
		foreach(@tchildren){		#if empty neg tag without neg_points defined
			if ($_->nodeType == 1 && $_->nodeName eq "neg" && $_->textContent eq "" && !defined $neg_points){
				die "Neg points not defined for question $acc";
			}
		}
		$acc++;
	}
	say "Toss-up points correctly indicated.";
} else {
	say "No toss-ups.";
}
#validate bonus set numbers
my $bonussets = $header->findnodes('bonus_sets')->shift()->textContent;
if ($bonussets != 0){
	my @bs = $quiz->findnodes('./bonus_set');
	my @bsnums = @bs;
	foreach(@bsnums){
		$_ = $_->findnodes('./number')->shift()->textContent;
	}
	my $acc = 1;
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
	}
	my @bps = $quiz->findnodes('./bonus_set');
	my @bps_val = @bps;
	foreach(@bs){
		my $bpstemp;
		if ($_->exists('./boni_in_set')){
			$bpstemp = $_->findnodes('./boni_in_set')->shift()->textContent;
		}
		my $b_p_s = $_->findnodes('./number')->shift()->textContent;
		$bps_val[$acc-1] = $bpstemp // $bps // die "No boni-per-set defined for bonus set $b_p_s";
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

	#validate bonus set points
	my $bs_points;
	if ($header->exists('./bonus_points')){
		$bs_points = $header->findnodes('./bonus_points')->shift()->textContent;
	}
	$acc = 1;
	foreach my $xx (@bs){
		my @boni = $xx->findnodes('./bonus');
		my $bqacc = 1;
		foreach (@boni){
			if (!($_->exists('./points') or $_->exists('../points_per_bonus') or $header->exists('./bonus_points'))){
				die "No points defined for bonus question $bqacc in set $acc";
			}
			$bqacc++;
		}
		$acc++;
	}
	say "Bonus set points allocated correctly."	
} else {
	say "No bonus sets.";
}

