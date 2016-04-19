#!/usr/local/bin/perl

use lib qw(./);

# Perl modules
use warnings ;
use Data::Dumper ;
use Getopt::Long;
use YAML;
use XML::Simple;

my $pgnam=$0;     # program name

# options
my ($LOGFILE, $VERBOSE,$HELP);
{ # process options
    GetOptions("logfile=s" => \$LOGFILE,
	       "verbose"   => \$VERBOSE,
               "help"      => \$HELP);
}

if($HELP || @ARGV < 1){
    die "Usage: $pgnam [options ...] xml_file yml_file

options:
  --logfile file
  --help
  --verbose
\n";
}

($xmlfile,$ymlfile)=@ARGV;

$ref = XMLin($xmlfile);
YAML::DumpFile($ymlfile,$ref);
