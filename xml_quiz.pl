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

#subroutine to process the toss-up tags
sub run_tu{
}

#subroutine to process the bonus set tags
sub run_bs{
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
if ($tblink eq "false"){
	foreach my $tu_tag (@tu_tags){
		&run_tu($tu_tag,$outp,$tu_points,$power_points);
	}
	foreach my $bs_tag (@bs_tags){
		&run_bs($bs_tag,$outp,$bonus_points,$boni_per_set);
	}
} else {
	my $acc = 0;
	while($acc < ($toss_ups >= $bonus_sets ? $toss_ups : $bonus_sets)){
		&run_tu($tu_tags[$acc],$outp,$tu_points,$power_points) if $acc < scalar @tu_tags;
		&run_bs($bs_tags[$acc],$outp,$bonus_points,$boni_per_set) if $acc < scalar @bs_tags;	
	}
}
$outp = join("\n",$outp,"\\end\{document\}\n");
say $outp;
my @qs = $dom->documentElement()->getChildrenByTagName("toss_up")->get_node(2)->getChildrenByTagName("question")->get_node(1)->getChildrenByTagName("text")->get_node(1);

say $qs[0];
say $qs[1];

