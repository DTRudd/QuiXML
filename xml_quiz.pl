#!/usr/bin/perl
use warnings;
use strict;
use v5.20;
use XML::LibXML;

#subroutine to validate file against quiz schema
sub quiz_validate{
	my $schema = XML::LibXML::Schema->new( location => "quiz.xsd" );
	eval {$schema->validate($_[0]);};
	if ($@) {
		die "XML input is invalid with schema:\n$@";
	}
}

#subroutine to process the header tag
sub run_header{
	#insert title
	my $title = $_[0]->getChildrenByTagName("title")->get_node(1)->textContent;
	$_[1] = join("\n",$_[1],"\\title\{$title\}\n\\begin\{abstract\}");

	#insert description
	my @desc = $_[0]->getElementsByTagName("description");
	if (scalar @desc > 0) {
		$_[8] = $desc[0]->textContent;
		$_[1] = join("\n",$_[1],"$_[8]");
	}

	#insert tu and bonus points
	my @tu = $_[0]->getElementsByTagName("toss_ups");
	$_[2] = $tu[0]->textContent;
	my @bs = $_[0]->getElementsByTagName("bonus_sets");
	$_[3] = $bs[0]->textContent;
	$_[1] = join("\n",$_[1],"$_[2] toss-ups, $_[3] bonus sets.");

	#say whether to skip bonuses
	my @tbl = $_[0]->getElementsByTagName("tblink");
	$_[4] = $tbl[0]->textContent;
	if ($_[4] eq "true") {
		$_[1] = join("",$_[1],"  Do not skip bonuses.");
	} else {
		$_[1] = join("",$_[1],"  Skip bonuses.");
	}

	#insert points per toss-up
	my @tup = $_[0]->getElementsByTagName("tu_points");
	if (scalar @tup > 0) {
		$_[5] = $tup[0]->textContent;
		$_[1] = join("",$_[1],"  $_[5] points per toss-up.") if scalar @tup > 0;
	}

	#insert points per bonus
	my @bp = $_[0]->getElementsByTagName("bonus_points");
	if (scalar @bp > 0){
		$_[6] = $bp[0]->textContent if scalar @bp > 0;
		$_[1] = join("",$_[1],"  $_[6] points per bonus.") if scalar @bp > 0;
	}

	#insert boni per set
	my @bps = $_[0]->getElementsByTagName("boni_per_set");
	if (scalar @bps > 0){
		$_[7] = $bps[0]->textContent if scalar @bps > 0;
		$_[1] = join("",$_[1],"  $_[7] boni per set.") if scalar @bps > 0;
	}

	#insert points for a power
	my @pp = $_[0]->getElementsByTagName("power_points");
	if (scalar @pp > 0){
		$_[9] = $pp[0]->textContent if scalar @pp > 0;
		$_[1] = join("",$_[1],"  Powers are worth $_[9].") if scalar @pp > 0;
	}

	#finish off
	$_[1] = join("\n",$_[1],"\\end\{abstract\}\n\\begin\{document\}\n\\maketitle");
}

sub validate_num{
	my @num = $_[0]->getElementsByTagName("number");
	my $num = $num[0]->textContent;
	die "Toss-up $num is incorrectly numbered." unless $num == $_[2] + 1 or $_[2] <= $_[3];
	$_[2] = $num;
	$_[1] = join("\n",$_[1],"$num.");
	$num;
}

#subroutine to process the toss-up tags
sub run_tu{
	my $num = &validate_num($_[0],$_[1],$_[4],$_[5]);
	my @points = $_[0]->getElementsByTagName("points");
	if (scalar @points == 0) {
		die "No value set for points in toss-up $num." unless defined $_[2];
	} else {
		my $points_txt = $points[0]->textContent;
		$_[1] = join("",$_[1],"  $points_txt points.");
	}
	my @q = $_[0]->getElementsByTagName("question");
	&run_tu_q($q[0],$_[1],$_[3]);
	my @ans = $_[0]->getElementsByTagName("answer");
	&run_ans($ans[0],$_[1]);
}

sub run_inst{
	my @inst = $_[0]->getElementsByTagName("instructions");
	$_[1] = join("\n",$_[1],$inst[0]->textContent) if scalar @inst > 0;
}

sub run_tu_q{
	&run_inst($_[0],$_[1]);
	my @text = $_[0]->getElementsByTagName("text");
	$_[1] = join("\n",$_[1],$text[0]->textContent);
}

sub run_ans{
	&run_inst($_[0],$_[1]);
	my @al = $_[0]->getElementsByTagName("al");
	&run_al($al[0],$_[1]);
}

sub run_al{
	my @la = $_[0]->getElementsByTagName("la");
	$_[1] = join("\n",$_[1],"");
	foreach my $la (@la){
		$_[1] = join(", ",$_[1],$la->textContent);
	}
}

#subroutine to process the bonus set tags
sub run_bs{
	my $num = &validate_num($_[0],$_[1],$_[4],$_[5]);
	my @points = $_[0]->getElementsByTagName("points_per_bonus");
	if (scalar @points == 0){
		die "No value set for points in bonus set $num." unless defined$_[2];
	} else {
		my $ppb = $points[0]->textContent;
		$_[1] = join("\n",$_[1],"$ppb points per bonus.");
	}
}


#main program
#begin tex document
my $outp = "\\documentclass\[12pt\]\{article\}";

#slurp the XML and parse it into DOM
my $parser = XML::LibXML->new();
my $file = "";
while (<STDIN>){
	$file = join("",$file,"$_\n");
}
my $dom = $parser->parse_string($file) or die "Cannot read file.";

#validate it against schema
&quiz_validate($dom);

#global quiz variables (may be overridden by local ones, exception thrown if undeclared and not overridden).
my $toss_ups;
my $bonus_sets;
my $tblink;
my $tu_points;
my $bonus_points;
my $boni_per_set;
my $description;
my $power_points;

#find and evaluate header tag
my @h_tag = $dom->documentElement()->getChildrenByTagName("header");
&run_header($h_tag[0],$outp,$toss_ups,$bonus_sets,$tblink,$tu_points,$bonus_points,$boni_per_set,$description,$power_points);
#find toss-up and bonus tags (if any)
my @tu_tags = $dom->documentElement()->getChildrenByTagName("toss_up");
my @bs_tags = $dom->documentElement()->getChildrenByTagName("bonus_set");

#evaluate tu and bonus tags
my $qnum = 0;
if ($tblink eq "false"){
	foreach my $tu_tag (@tu_tags){
		&run_tu($tu_tag,$outp,$tu_points,$power_points,$qnum,$toss_ups);
	}
	$qnum = 0;
	$outp = join("\n",$outp,"Bonus sets.");
	foreach my $bs_tag (@bs_tags){
		&run_bs($bs_tag,$outp,$bonus_points,$boni_per_set,$qnum,$bonus_sets);
	}
} else {
	my $acc = 0;
	while($acc < ($toss_ups >= $bonus_sets ? $toss_ups : $bonus_sets)){
		&run_tu($tu_tags[$acc],$outp,$tu_points,$power_points,$qnum,$toss_ups) if $acc < scalar @tu_tags;
		&run_bs($bs_tags[$acc],$outp,$bonus_points,$boni_per_set,$qnum,$bonus_sets) if $acc < scalar @bs_tags;
		$qnum++;
	}
}
$outp = join("\n",$outp,"\\end\{document\}\n");
say $outp;

