#!/usr/bin/env perl

use lib qw(../Packages);
use lib qw(Packages);

# Perl modules
# use warnings ;
use Data::Dumper ;
use Getopt::Long;
use File::Basename;
use YAML;
use YAMLUtil;

my $pgnam=basename($0);     # program name

# options
my ($LOGFILE, $VERBOSE,$HELP);
{ # process options
    GetOptions(
	       "verbose"   => \$VERBOSE,
               "help"      => \$HELP);
}

if($HELP || @ARGV < 2){
    print "$pgnam: converts YAML file to Perl data structure.\n";
    die "Usage: $pgnam [options ...] yaml_file perl_file

options:
  --help
  --verbose
\n";
}

my ($ifile,$ofile)=@ARGV;
my $INPUT_DB;

my $SCHEMA=$ifile;
die "$0: $! $ifile\n" unless -r $ifile;
open my($OFILE), '>', $ofile or die "$0: $! $ofile\n";


$YAML::UseAliases=0;    # minimize references
($INPUT_DB) = YAML::LoadFile( $SCHEMA );
# Clean up the inner references in the tree
# Need to fix in YAML package
mergekeys_loop( $INPUT_DB );


$d = Data::Dumper->new([$INPUT_DB], [qw(INPUT_DB)]);
$d->Terse(1);

print $OFILE $d->Dump;
