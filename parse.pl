#!/usr/bin/perl

use strict;
use warnings;
use MongoDB;
use File::Spec;

my $client = MongoDB::MongoClient->new or die("Couldn't connect");
my $db = $client->get_database('shakespeare') or die ("No db");
my $plays = $db->get_collection('plays') or die("no collection");

foreach my $arg (@ARGV) {
    my @files = <$arg/*>;
    foreach my $file (@files) {
	print "$file\n";
	my $type = (File::Spec->splitdir($arg))[-1];
	open(my $lines, $file) or die "Can't open $file: $!";
	my $title;
	my $actI = 0;
	my $act;
	my $speaker;
	my $scene;
	my $locale;
	my $speechline;
	my $direction = 0;
	my $count = 0;
	my $linecount = 0;
	my $speechNumber = 0;
	my $stillInScene = 0;
	my $stageDirection = 0;
	my $stageLine;
	while(defined(my $line = <$lines>)) {
	    $count++;
	    if($line =~ m/^\s+$/) {
		$stillInScene = 0;
		next;
	    }
	    if(!defined($title)) {
		chomp(($title) = ($line =~ m/\s*(.+)\s*/));
		next;
	    }
	    if($line =~ m/ACT I/i) {
		$actI = 1;
	    }
	    if($actI == 1) {
		next if($line =~ m/^\s+?$title\s*?/);
		if($line =~ m/^ACT/) {
		    ($act) = ($line =~ m/act ([a-z]+)/i);
		}
		elsif($line =~ m/^SCENE/) {
		    $stillInScene = 1;
		    ($scene) = ($line =~ m/scene\s+([a-z]+)/i);
		    ($locale) = ($line =~ m/scene\s+[a-z]+:*\s+?(.+)/i);
		    #Often times locale will not be specified
		    if(!defined($locale)) {
			$locale = "";
		    }
		    $speaker = undef;
		}
		elsif($line =~ m/^[^\t]/) {
		    if($line =~ m/[^\t]+\t.+/) {
			if(defined($speaker)) {
			    $speechNumber++;
			}
			($speaker, $speechline) = ($line =~ m/^([^\t]+)\t(.+)/);
			$linecount++;
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "speaker"=>"$speaker", "line"=>"$speechline","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
		    }
		}	
		elsif($line =~ m/\t/) {
		    if($line =~ m/^\s*\[.+\]\s*$/) {
			if($line =~ m/enter/i and !defined($speaker)) {
			    $stageDirection = () = $line =~ /[A-Z][A-Z|\s]{2,}/g;
			    if($stageDirection == 1) {
				($speaker) = ($line =~ m/([A-Z][A-Z|\s]{2,})/);
			    }
			}
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "stagedirection"=>"true", "line"=>"$line","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
			$linecount++;
		    }
		    elsif($stillInScene == 1) {
			my ($temp) = ($line =~ m/^\s*(.+)/);
			$scene .= $temp;
		    }
		    elsif($line =~ m/\[/ && $line !~m/\]/) {
			$stageLine = $line;
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "stagedirection"=>"true", "line"=>"$line","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
			$linecount++;
			$direction = 1;
		    }
		    elsif($line =~ m/\]/ && $line !~m/\[/) {
			$stageLine .= $line;
			if($stageLine =~ m/enter/i and !defined($speaker)) {
			    $stageDirection = () = $stageLine =~ /([A-Z][A-Z\s?]{2,})/g;
			    if($stageDirection == 1) {
				($speaker) = ($stageLine =~ m/([A-Z][A-Z\s?]{2,})/);
			    }			
			}
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "stagedirection"=>"true", "line"=>"$line","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
			$linecount++;
			$direction = 0;
		    }
		    elsif($direction == 1) {
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "stagedirection"=>"true", "line"=>"$line","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
			$linecount++;
			$stageLine .= $line;
		    }
		    elsif($direction == 0) {
			my ($temp) = ($line =~ m/\t(.+)/);
			$linecount++;
			$plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "speaker"=>"$speaker", "line"=>"$temp","lineNumber"=>$linecount, "type"=>"$type", "speech"=>$speechNumber}) or die("Something wrong!");
			$speechline .= "\n".$temp;
		    }
		}
	    }
	}
    }
}
