#!/usr/bin/env perl

use File::Basename;
my $pgnam=basename($0);     # program name

my ($ifile,$ofile)=@ARGV;

if($HELP || @ARGV < 2){
    print "$pgnam: processes include statements in file.\n";
    die "Usage: $pgnam in_file out_file\n";
}

open my($IFILE), '<', $ifile or die "$pgnam: $! $ifile\n";
open my($OFILE), '>', $ofile or die "$pgnam: $! $ofile\n";

while(<$IFILE>){
    if(/^\#include +(.*)/){
	open my($CFILE), '<', $1 or die "$pgnam: $! $1\n";
	while(<$CFILE>){
	    print $OFILE "$_";
	}
	close $CFILE;
    }
    else{
	print $OFILE "$_";
    }
}
close $OFILE;
