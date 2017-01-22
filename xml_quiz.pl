#!/usr/bin/perl
use warnings;
use strict;
use v5.20;
use XML::LibXML;
use Roman;

#subroutine to validate file against quiz schema
sub quiz_validate{
	my ($input) = @_;
	my $schema = XML::LibXML::Schema->new( location => 'quiz.xsd' );
	eval {$schema->validate($input);};
	if ($@) {
		die "XML input is invalid with schema:\n$@";
	}
}

sub run_inst{
	my ($tag,$outp) = @_;
	my @inst = $tag->getElementsByTagName('instructions');
	if (scalar @inst > 0) {
		my $inst_content = $inst[0]->textContent;
		$outp = join("\n",$outp,"\\textit\{\(Note: $inst_content\)\}");
	}
	return $outp;
}

sub run_tu_q{
	my ($tag,$outp) = @_;
	$outp = run_inst($tag,$outp);
	my @text = $tag->getElementsByTagName('text');
	my $text_content = $text[0]->textContent;
	$outp = join('  ',$outp,"$text_content \\\\");
	return $outp;
}


sub run_bq{
	my ($tag,$outp) = @_;
	$outp = run_inst($tag,$outp);
	my @text = $tag->getElementsByTagName('text');
	my $text_content = $text[0]->textContent;
	$outp = join("\n",$outp,"$text_content\\\\");
	return $outp;
}

sub run_ans{
	my ($tag,$outp) = @_;
	my @al = $tag->getElementsByTagName('al');
	$outp = join("\n",$outp,'ANSWER: ');
	$outp = run_al($al[0],$outp);
	$outp = run_inst($tag,$outp);
	return $outp;
}

sub run_al{
	my ($tag,$outp) = @_;
	my @la = $tag->getElementsByTagName('la');
	$outp = join("\n",$outp,'');
	foreach my $la (@la){
		my $la_content = $la->textContent;
		$outp = join('',$outp,"\\textbf\{$la_content\}");
		if($la eq $la[$#la]){
			$outp = join('',$outp,'.');
		} else {
			$outp = join('',$outp,', ');
		}
	}
	return $outp;
}

#subroutine to process the header tag
sub run_header{
	my ($tag,$outp) = @_;
	#insert title
	my $title = $tag->getChildrenByTagName('title')->get_node(1)->textContent;
	$outp = join("\n",$outp,"\\usepackage\{titlesec\}","\\titlespacing*\{\\subsubsection\}\{0pt\}\{0ex\}\{1.5ex plus .2ex\}","\\titleformat\{\\subsection\}\[runin\]\{\}\{\}\{\}\{\}\[\]","\\titleformat\{\\subsubsection\}\[runin\]\{\}\{\}\{\}\{\}\[\]");
	$outp = join("\n",$outp,"\\title\{$title\}","\\begin\{document\}","\\begin\{abstract\}");
	return $outp;
}

	#insert description
sub get_desc{
	my ($tag) = @_;
	my @desc = $tag->getElementsByTagName('description');
	if (scalar @desc > 0) {
		my $description = $desc[0]->textContent;
		return $description;
	} else {
		return 'NODESC';
	}
}

	#insert tu and bonus points
sub get_tus {
	my ($tag) = @_;
	my @tu = $tag->getElementsByTagName('toss_ups');
	my $toss_ups = $tu[0]->textContent;
	return $toss_ups;
}

sub get_bs {
	my ($tag) = @_;
	my @bs = $tag->getElementsByTagName('bonus_sets');
	my $bonus_sets = $bs[0]->textContent;
	return $bonus_sets;
}

sub get_tblink {
	#say whether to skip bonuses
	my ($tag) = @_;
	my @tbl = $tag->getElementsByTagName('tblink');
	my $tblink = $tbl[0]->textContent;
	return $tblink;
}

sub get_tu_points {
	#insert points per toss-up
	my ($tag) = @_;
	my @tup = $tag->getElementsByTagName('tu_points');
	my $tu_points;
	if (scalar @tup > 0) {
		$tu_points = $tup[0]->textContent;
	} else {
		$tu_points = 'NOTUPOINTS';
	}
	return $tu_points;
}

sub get_bonus_points {
	#insert points per bonus
	my ($tag) = @_;
	my @bp = $tag->getElementsByTagName('bonus_points');
	my $bonus_points;
	if (scalar @bp > 0){
		$bonus_points = $bp[0]->textContent;
	} else {
		$bonus_points = 'NOBPOINTS';
	}
	return $bonus_points;
}

sub get_bps {
	#insert boni per set
	my ($tag) = @_;
	my @bps = $tag->getElementsByTagName('boni_per_set');
	my $boni_per_set;
	if (scalar @bps > 0){
		$boni_per_set = $bps[0]->textContent;
	} else {
		$boni_per_set = 'NOBPS';
	}
	return $boni_per_set;
}

sub get_pp {
	#insert points for a power
	my ($tag) = @_;
	my @pp = $tag->getElementsByTagName('power_points');
	my $power_points;
	if (scalar @pp > 0){
		$power_points = $pp[0]->textContent;
	} else {
		$power_points = 'NOPPS';
	}
	return $power_points;
}

sub validate_num {
	my ($tag,$outp,$ext_num,$string) = @_;
	my @num = $tag->getElementsByTagName('number');
	my $num = $num[0]->textContent;
	die "$string $num is incorrectly numbered." unless $num == $ext_num + 1;
	$outp = join("\n",$outp,"\\subsection*\{\\textbf\{$num.\}\}");
	return $outp;
}

sub validate_num_roman{
	my ($tag,$outp,$ext_num,$string) = @_;
	my @num = $tag->getElementsByTagName('number');
	my $num = $num[0]->textContent;
	die "$string $num is incorrectly numbered." unless $num == $ext_num + 1;
	my $roman = roman($num);
	$outp = join("\n",$outp,"\\subsubsection*\{\\textbf\{$roman.\}\}");
	return $outp;
}

#subroutine to process the toss-up tags
sub run_tu{
	my ($tag,$outp,$ext_tup,$num,$toss_ups) = @_;
	my @points = $tag->getElementsByTagName('points');
	if (scalar @points == 0) {
		die "No value set for points in toss-up $num." unless defined $ext_tup;
	} else {
		my $points_txt = $points[0]->textContent;
		$outp = join('',$outp," \\textit\{This toss-up is worth \\textbf\{$points_txt\} points.\}\\\\");
	}
	my @q = $tag->getElementsByTagName('question');
	$outp = run_tu_q($q[0],$outp);
	my @ans = $tag->getElementsByTagName('answer');
	$outp = run_ans($ans[0],$outp);
	return $outp;
}

#subroutine to process the bonus set tags
sub run_bs{
	my ($tag,$outp,$ext_ppb,$ext_bps,$bonus_sets) = @_;
	my @points = $tag->getElementsByTagName('points_per_bonus');
	my $ppb;
	if (scalar @points != 0){
		$ppb = $points[0]->textContent;
		$outp = join("\n",$outp,"\\textit\{These boni are worth \\textbf\{$ppb\} points each.\}");
	}
	$outp = run_inst($tag,$outp);
	my @opener = $tag->getElementsByTagName('opener');
	$outp = join("\n",$outp,$opener[0]->textContent);
	my $acc = 0;
	my @boni = $tag->getElementsByTagName('bonus');
	foreach my $bonus (@boni){
		$outp = validate_num_roman($bonus,$outp,$acc,'Bonus');
		$outp = run_bonus($bonus,$outp,defined $ppb ? $ppb : $ext_ppb,$ext_bps,$bonus_sets,$acc);
		$acc++;
	}
	return $outp;
}

sub run_bonus {
	my ($tag,$outp,$ext_ppb,$ext_bps,$bonus_sets,$acc) = @_;
	my @points = $tag->getElementsByTagName('points');
	if (scalar @points == 0) {
		my $num = $acc+1;
		die "No value set for points in toss-up $num." unless defined $ext_ppb;
	} else {
		my $points_txt = $points[0]->textContent;
		$outp = join('',$outp," \\textit\{This bonus is worth \\textbf{$points_txt\} points.\}");
	}
	my @bq = $tag->getElementsByTagName('question');
	$outp = run_bq($bq[0],$outp);
	my @ans = $tag->getElementsByTagName('answer');
	$outp = run_ans($ans[0],$outp);
	return $outp;
}

#main program
#begin tex document
my $outp = "\\documentclass\[12pt\]\{article\}";

#slurp the XML and parse it into DOM
my $parser = XML::LibXML->new();
my $file = "";
while (<STDIN>){
	$file = join('',$file,"$_\n");
}
my $dom = $parser->parse_string($file) or die 'Cannot read file.';

#validate it against schema
quiz_validate($dom);

#global quiz variables (may be overridden by local ones, exception thrown if undeclared and not overridden).

#find and evaluate header tag
my @h_tag = $dom->documentElement()->getChildrenByTagName('header');
$outp = run_header($h_tag[0],$outp);

my $description = get_desc($h_tag[0]);
$outp = join("\n",$outp,"$description \\\\") unless $description eq 'NODESC';

my $toss_ups = get_tus($h_tag[0]);
my $bonus_sets = get_bs($h_tag[0]);
$outp = join("\n",$outp,"\\textbf\{$toss_ups\} toss-ups, \\textbf\{$bonus_sets\} bonus sets.");

my $tblink = get_tblink($h_tag[0]);
if ($tblink eq 'true') {
	$outp = join('',$outp,'  Do not skip bonuses.');
} else {
	$outp = join('',$outp,'  Skip bonuses.');
}

my $tu_points = get_tu_points($h_tag[0]);
$outp = join('',$outp,"  \\textbf\{$tu_points\} points per toss-up.") unless $tu_points eq 'NOTUPOINTS';

my $bonus_points = get_bonus_points($h_tag[0]);
$outp = join('',$outp,"  \\textbf\{$bonus_points\} points per bonus.") unless $bonus_points eq 'NOBPOINTS';

my $boni_per_set = get_bps($h_tag[0]);
$outp = join('',$outp,"  \\textbf\{$boni_per_set\} boni per set.") unless $boni_per_set eq 'NOBPS';

my $power_points = get_pp($h_tag[0]);
$outp = join('',$outp,"  Powers are worth \\textbf\{$power_points\}.\\\\") unless $power_points eq 'NOPPS';

$outp = join("\n",$outp,"\\end\{abstract\}\n\\maketitle");

#find toss-up and bonus tags (if any)
my @tu_tags = $dom->documentElement()->getChildrenByTagName('toss_up');
my @bs_tags = $dom->documentElement()->getChildrenByTagName('bonus_set');
die 'Incorrect number of toss-ups' if scalar @tu_tags != $toss_ups;
die 'Incorrect number of bonus sets' if scalar @bs_tags != $bonus_sets;

#evaluate tu and bonus tags
my $acc = 0;
if ($tblink eq 'false'){
	$outp = join("\n",$outp,"\\section*\{Toss-ups\}\n") if $toss_ups > 0;
	foreach my $tu_tag (@tu_tags){
		$outp = validate_num($tu_tag,$outp,$acc,'Toss-up');
		$acc++;
		$outp = run_tu($tu_tag,$outp,$tu_points,$acc,$toss_ups);
	}
	$acc = 0;
	$outp = join("\n",$outp,"\\section*\{Bonus sets\}\n") if $bonus_sets > 0;
	foreach my $bs_tag (@bs_tags){
		$outp = validate_num($bs_tag,$outp,$acc,'Bonus set');
		$acc++;
		$outp = run_bs($bs_tag,$outp,$bonus_points,$boni_per_set,$acc,$bonus_sets);
	}
} else {
	while($acc < ($toss_ups >= $bonus_sets ? $toss_ups : $bonus_sets)){
		if ($acc < scalar @tu_tags) {
			$outp = validate_num($tu_tags[$acc],$outp,$acc,'Toss-up');
			$outp = run_tu($tu_tags[$acc],$outp,$tu_points,$toss_ups);
		}
		if ($acc < scalar @bs_tags) {
			$outp = validate_num($tu_tags[$acc],$outp,$acc,'Bonus set');
			$outp = run_bs($bs_tags[$acc],$outp,$bonus_points,$boni_per_set,$bonus_sets);
		}
		$acc++;
	}
}
$outp = join("\n",$outp,"\\end\{document\}\n");
say $outp;
