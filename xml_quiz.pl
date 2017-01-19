#!/usr/bin/perl
use warnings;
use strict;
use v5.20;
use XML::LibXML;

#subroutine to validate file against quiz schema
sub quiz_validate{
	my ($input) = @_;
	my $schema = XML::LibXML::Schema->new( location => "quiz.xsd" );
	eval {$schema->validate($input);};
	if ($@) {
		die "XML input is invalid with schema:\n$@";
	}
}

sub run_inst{
	my ($tag,$outp) = @_;
	my @inst = $tag->getElementsByTagName("instructions");
	if (scalar @inst > 0) {
		my $inst_content = $inst[0]->textContent;
		$outp = join("\n",$outp,"\\textit\{Instructions: $inst_content \}\\\\");
		$_[1] = $outp;
	}
}

sub run_tu_q{
	my ($tag,$outp) = @_;
	run_inst($tag,$outp);
	my @text = $tag->getElementsByTagName("text");
	my $text_content = $text[0]->textContent;
	$outp = join("\n",$outp," $text_content \\\\");
	$_[1] = $outp;
}


sub run_bq{
	my ($tag,$outp) = @_;
	run_inst($tag,$outp);
	my @text = $tag->getElementsByTagName("text");
	my $text_content = $text[0]->textContent;
	$outp = join("\n",$outp," $text_content \\\\");
	$_[1] = $outp;
}

sub run_ans{
	my ($tag,$outp) = @_;
	my @al = $tag->getElementsByTagName("al");
	run_al($al[0],$outp);
	run_inst($tag,$outp);
	$_[1] = $outp;
}

sub run_al{
	my ($tag,$outp) = @_;
	my @la = $tag->getElementsByTagName("la");
	$outp = join("\n",$outp,"");
	foreach my $la (@la){
		my $la_content = $la->textContent;
		$outp = join(", ",$outp,"$la_content \\\\");
	}
	$_[1] = $outp;
}

#subroutine to process the header tag
sub run_header{
	my ($tag,$outp,$toss_ups,$bonus_sets,$tblink,$tu_points,$bonus_points,$boni_per_set,$description,$power_points) = @_;
	#insert title
	my $title = $tag->getChildrenByTagName("title")->get_node(1)->textContent;
	$outp = join("\n",$outp,"\\title\{$title\}\n\\begin\{document\}\n\\begin\{abstract\}");

	#insert description
	my @desc = $tag->getElementsByTagName("description");
	if (scalar @desc > 0) {
		$description = $desc[0]->textContent;
		$outp = join("\n",$outp,"$description \\\\");
	}

	#insert tu and bonus points
	my @tu = $tag->getElementsByTagName("toss_ups");
	$toss_ups = $tu[0]->textContent;
	$_[2] = $toss_ups;
	my @bs = $tag->getElementsByTagName("bonus_sets");
	$bonus_sets = $bs[0]->textContent;
	$_[3] = $bonus_sets;
	$outp = join("\n",$outp,"\\textbf\{$toss_ups\} toss-ups, \\textbf\{$bonus_sets\} bonus sets.");

	#say whether to skip bonuses
	my @tbl = $tag->getElementsByTagName("tblink");
	$tblink = $tbl[0]->textContent;
	$_[4] = $tblink;
	if ($tblink eq "true") {
		$outp = join("",$outp,"  Do not skip bonuses.");
	} else {
		$outp = join("",$outp,"  Skip bonuses.");
	}

	#insert points per toss-up
	my @tup = $tag->getElementsByTagName("tu_points");
	if (scalar @tup > 0) {
		$tu_points = $tup[0]->textContent;
		$outp = join("",$outp,"  \\textbf\{$tu_points\} points per toss-up.") if scalar @tup > 0;
	}
	$_[5] = $tu_points;

	#insert points per bonus
	my @bp = $tag->getElementsByTagName("bonus_points");
	if (scalar @bp > 0){
		$bonus_points = $bp[0]->textContent if scalar @bp > 0;
		$outp = join("",$outp,"  \\textbf\{$bonus_points\} points per bonus.") if scalar @bp > 0;
	}
	$_[6] = $bonus_points;

	#insert boni per set
	my @bps = $tag->getElementsByTagName("boni_per_set");
	if (scalar @bps > 0){
		$boni_per_set = $bps[0]->textContent if scalar @bps > 0;
		$outp = join("",$outp,"  \\textbf\{$boni_per_set\} boni per set.") if scalar @bps > 0;
	}
	$_[7] = $boni_per_set;

	#insert points for a power
	my @pp = $tag->getElementsByTagName("power_points");
	if (scalar @pp > 0){
		$power_points = $pp[0]->textContent if scalar @pp > 0;
		$outp = join("",$outp,"  Powers are worth \\textbf\{$power_points\}.\\\\") if scalar @pp > 0;
	}
	$_[9] = $power_points;

	#finish off
	$outp = join("\n",$outp,"\\end\{abstract\}\n\\maketitle");
	$_[1] = $outp;
}

sub validate_num{
	my ($tag,$outp,$ext_num,$string) = @_;
	my @num = $tag->getElementsByTagName("number");
	my $num = $num[0]->textContent;
	die "$string $num is incorrectly numbered." unless $num == $ext_num + 1;
	$ext_num = $num;
	$_[2] = $ext_num;
	$outp = join("\n",$outp,"\\textbf\{$num\}.");
	$_[1] = $outp;
	$num;
}

#subroutine to process the toss-up tags
sub run_tu{
	my ($tag,$outp,$ext_tup,$ext_num,$toss_ups) = @_;
	my $num = validate_num($tag,$outp,$ext_num,"Toss-up");
	my @points = $tag->getElementsByTagName("points");
	if (scalar @points == 0) {
		die "No value set for points in toss-up $num." unless defined $ext_tup;
	} else {
		my $points_txt = $points[0]->textContent;
		$outp = join("",$outp," \\textbf\{$points_txt\} points.");
	}
	my @q = $tag->getElementsByTagName("question");
	run_tu_q($q[0],$outp);
	my @ans = $tag->getElementsByTagName("answer");
	run_ans($ans[0],$outp);
	$_[1] = $outp;
	$_[3] = $ext_num;
}

#subroutine to process the bonus set tags
sub run_bs{
	my ($tag,$outp,$ext_ppb,$ext_bps,$ext_num,$bonus_sets) = @_;
	my $num = validate_num($tag,$outp,$ext_num,"Bonus set");
	my @points = $tag->getElementsByTagName("points_per_bonus");
	my $ppb;
	if (scalar @points != 0){
		$ppb = $points[0]->textContent;
		$outp = join("\n",$outp,"$ppb points per bonus.");
	}
	run_inst($tag,$outp);
	my @opener = $tag->getElementsByTagName("opener");
	$outp = join("\n",$outp,$opener[0]->textContent);
	my $bnum = 0;
	my @boni = $tag->getElementsByTagName("bonus");
	foreach my $bonus (@boni){
		run_bonus($bonus,$outp,defined $ppb ? $ppb : $ext_ppb,$ext_bps,$bnum,$bonus_sets);
	}
	$_[1] = $outp;
	$_[4] = $ext_num;
}

sub run_bonus {
	my ($tag,$outp,$ext_ppb,$ext_bps,$ext_num,$bonus_sets) = @_;
	my $num = validate_num($tag,$outp,$ext_num,"Bonus");
	my @points = $tag->getElementsByTagName("points");
	if (scalar @points ==0) {
		die "No value set for points in toss-up $num." unless defined $ext_ppb;
	} else {
		my $points_txt = $points[0]->textContent;
		$outp = join("",$outp," $ext_ppb points.");
	}
	my @bq = $tag->getElementsByTagName("question");
	run_bq($bq[0],$outp);
	my @ans = $tag->getElementsByTagName("answer");
	run_ans($ans[0],$outp);
	$_[1] = $outp;
	$_[4] = $ext_num;
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
quiz_validate($dom);

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
run_header($h_tag[0],$outp,$toss_ups,$bonus_sets,$tblink,$tu_points,$bonus_points,$boni_per_set,$description,$power_points);
#find toss-up and bonus tags (if any)
my @tu_tags = $dom->documentElement()->getChildrenByTagName("toss_up");
my @bs_tags = $dom->documentElement()->getChildrenByTagName("bonus_set");
die "Incorrect number of toss-ups" if scalar @tu_tags != $toss_ups;
die "Incorrect number of bonus sets" if scalar @bs_tags != $bonus_sets;
#evaluate tu and bonus tags
my $qnum = 0;
if ($tblink eq "false"){
	foreach my $tu_tag (@tu_tags){
		run_tu($tu_tag,$outp,$tu_points,$qnum,$toss_ups);
	}
	$qnum = 0;
	$outp = join("\n",$outp,"Bonus sets.");
	foreach my $bs_tag (@bs_tags){
		run_bs($bs_tag,$outp,$bonus_points,$boni_per_set,$qnum,$bonus_sets);
	}
} else {
	my $acc = 0;
	while($acc < ($toss_ups >= $bonus_sets ? $toss_ups : $bonus_sets)){
		run_tu($tu_tags[$acc],$outp,$tu_points,$qnum,$toss_ups) if $acc < scalar @tu_tags;
		run_bs($bs_tags[$acc],$outp,$bonus_points,$boni_per_set,$qnum,$bonus_sets) if $acc < scalar @bs_tags;
		$qnum++;
	}
}
$outp = join("\n",$outp,"\\end\{document\}\n");
say $outp;

