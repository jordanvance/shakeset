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
	my $linecount;
	while(defined(my $line = <$lines>)) {
	    $count++;
	    if($line =~ m/^\s+$/) {
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
		    ($act) = ($line =~ m/act ([a-z]+?)/i);
		}
		elsif($line =~ m/^SCENE/) {
		    ($scene) = ($line =~ m/scene\s+([a-z]+)/i);
		    ($locale) = ($line =~ m/scene\s+[a-z]+:*\s+?(.+)/i);
		}
		elsif($line =~ m/^[^\t]/) {
		    if($line =~ m/[^\t]+\t.+/) {
			if(defined($speaker)) {
			    $plays->save({"title"=>"$title", "act"=>"$act", "scene"=>"$scene", "location"=>"$locale", "speaker"=>"$speaker", "lines"=>"$speechline","lineCount"=>$linecount, "type"=>"$type"}) or die("Something wrong!");
			}
			($speaker, $speechline) = ($line =~ m/^([^\t]+)\t(.+)/);
			$linecount=1;
		    }
		}	
		elsif($line =~ m/\t/) {
		    if($line =~ m/\s*\[.+\]\s*\n/) {
			next;
		    }
		    if($line =~ m/\[/) {
			$direction = 1;
		    }
		    if($line =~ m/\]/) {
			$direction = 0;
		    }
		    if($direction == 0) {
			my ($temp) = ($line =~ m/\t(.+)/);
			$speechline .= "\n".$temp;
			$linecount++;
		    }
		}
	    }
	}
    }
}
