#!/usr/bin/perl

use strict;
use warnings;
use MongoDB;
use File::Spec;
use boolean;
use Tie::IxHash;
use MongoDB::Cursor;
use feature 'say';
use Data::Dump q(dump);
use File::Path qw(make_path);

my $client = MongoDB::MongoClient->new or die("Couldn't connect");
my $db = $client->get_database('shakespeare') or die ("No db");
my $plays = $db->get_collection('plays') or die("no collection");

my $title = undef;
my $act = undef;
my $scene = undef;
my $speech = undef;
my $speaker = undef;
my $location = undef;

my $curDivs = 0;

my $actDiv = "<div class='act'>\n";
my $actSpanf = "<span id='act%s' class='acttitle centerable'>Act %s</span>\n";
my $sceneDiv = "<div class='scene'>\n";
my $sceneSpanf = "<span id='act%s-scene%s' class='centerable'>Scene %s<br/>%s</span>\n";
my $speakerDiv = "<div class='speech'>\n";
my $speakerSpanf = "<span id='act%s-scene%s-speech%d' class='centerable %s'>%s</span>\n";
my $linesDiv = "<div class='lines'>\n";
my $lineSpanf = "<span id='%d' class='%s'>%s</span><br />\n";
my $closeDiv = "</div><br />\n";
my $actHR = "<hr class='actHR'>";
my $sceneHR = "<hr class='sceneHR'>";
my @colors = ("red", "black");
my $colorDefault = "black";



my $result = $db->run_command(["distinct"=> "plays", 
			       "key"=>"type", 
			       "query"=>{}]);
foreach my $type ( @{$result->{values}}) {
    my $titleResult = $db->run_command(["distinct"=>"plays", "key"=>"title", "query"=>{"type"=>"$type"}]);
    foreach $title( @{$titleResult->{values}}) {
	print "$type $title\n";
	mkdir($type);
	open(my $fd, ">", "$type/$title.HTML");
	print $fd "<head><link rel='stylesheet' href='../css/shakeset.css'><script src='http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js'></script><script src='../js/shakeset.js'></script></head><body>";

	print $fd "<div id='header'><h1>$title</h1></div><div class='body'>";
	my $color;
	my $cursors = $plays->query({title => $title})->sort({lineNumber=>1});
	while(my $object = $cursors->next) {
	    $color = $colorDefault;
	    if(defined($object->{speech})) {
		my $index = $object->{speech} % 2;
		$color = $colors[$index];
	    }
	    if(!defined($act) || $act ne $object->{act}) {
		while($curDivs > 0) {
		    print $fd "$closeDiv";
		    $curDivs--;
		}
		print $fd $actDiv;
		$curDivs = 0;
		$act = $object->{act};
		print $fd sprintf($actSpanf, $act, $act);
		$curDivs++;
		my $scene = undef;
		my $speaker = undef;
	    }
	    if(!defined($scene) || $scene ne $object->{scene}) {
		while($curDivs > 1) {
		    print $fd $closeDiv;
		    $curDivs--;
		}
		print $fd $sceneDiv;
		$scene = $object->{scene};
		$location = $object->{location};
		print $fd sprintf($sceneSpanf, $act, $scene, $scene, $location);
		$curDivs++;
		$speaker = undef;
		$speech = undef;
	    }
	    if(!defined($speech) || $speech!=$object->{speech}) {
		while($curDivs > 2) {
		    print $fd $closeDiv;
		    $curDivs--;
		}
		$speech = $object->{speech};
		if(!defined($object->{speaker})) {
		    my $lineNo = $object->{lineNumber};
		    my $tempCursor = $plays->find({title=>$title, stageDirection => {'$ne' => true}, speech => $speech, lineNumber=> {'$gt'=> $lineNo}, speaker=>{'$exists'=>true}})->sort({lineNumber=>1})->limit(1);
		    while(my $tempObj = $tempCursor->next) {
			if(defined($tempObj->{speaker})) {
			    $speaker = $tempObj->{speaker};
			    last;
			}
		    }
		} else {
		    $speaker = $object->{speaker};
		}
		#print $fd "<br /><br />";
		print $fd $speakerDiv;
		print $fd sprintf($speakerSpanf, $act, $scene, $speech, $color, $speaker);
		$curDivs++;
		print $fd $linesDiv;
		$curDivs++;
	    }
	    print $fd sprintf($lineSpanf, $object->{lineNumber}, $color, $object->{line});
	}
	print $fd "</div></body>";
    }
}
