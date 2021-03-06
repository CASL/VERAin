#!/usr/bin/env perl

# use lib qw(./Packages);

#
# Dynamic path setting to accomodate vri repositories
#
my ($filename, $directory) = GetPaths();
eval "use lib qw(${directory}Packages);
use YAML;
use YAMLUtil;
use KeyTree;
use REACTOR;
use REACTORBlock;
use PL;
use XMLPack;
use Clone::PP qw(clone);
use TypeUtils;
use Cellmaps";

sub GetPaths()
{
    use Cwd 'abs_path';
    use File::Basename;
    my $pscript=abs_path($0);
    my($filename, $directory) = fileparse($pscript);
    return ($filename, $directory);
}

#
# Standard Perl modules
#
use warnings ;
use Data::Dumper ;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use File::Spec::Functions;

#
# Data structure with reactor file input commands
# to initiate hash tree for the parsed input and
# to initiate subtrees
#
my $INPUT_DB;

#
# The resulting hash tree that contains parsed reactor
# input data
#
my $MAIN_DB;

my $pgnam=basename($0);                # program name
my @VERSION=('major'=>2,               # open sourced
	     'minor'=>0,
	     'date'=>20160415);

#
# Input schema to initiate INPUT_DB
#
my $SCHEMA;
#
# Schemas for the format of the output blocks in PL
#
my @BLOCKS;

#
# REGULAR DEVELOPER SECTION
#
# Data trees, default To add new INPUT block, add new block section in
# FILE Templates/Directory.yml
#
# To add new OUTPUT block, add new block YAML file in DIRECTORY
# Templates/ that has the same basename as the block. Then add the
# block name to array @BLOCKS below. Also add entry to $SCH_PL hash
# below with #include line and follow syntax of other entries.
#
$SCHEMA="${directory}Templates/Directory.yml";
@BLOCKS=('CASEID','STATES','CORE','ASSEMBLIES',
	 'CONTROLS','DETECTORS','INSERTS',
	 'SHIFT','EDITS','COBRATF','COUPLING',
	 'MPACT','MAMBA','BISON','TIAMAT','RUN');

$SCH_PL{ 'CASEID' } = (
#include pyml/CASEID.pyml
)[0];
$SCH_PL{ 'STATES' } = (
#include pyml/STATES.pyml
)[0];
$SCH_PL{ 'CORE' } = (
#include pyml/CORE.pyml
)[0];
$SCH_PL{ 'ASSEMBLIES' } = (
#include pyml/ASSEMBLIES.pyml
)[0];
$SCH_PL{ 'CONTROLS' } = (
#include pyml/CONTROLS.pyml
)[0];
$SCH_PL{ 'DETECTORS' } = (
#include pyml/DETECTORS.pyml
)[0];
$SCH_PL{ 'INSERTS' } = (
#include pyml/INSERTS.pyml
)[0];
$SCH_PL{ 'SHIFT' } = (
#include pyml/SHIFT.pyml
)[0];
$SCH_PL{ 'EDITS' } = (
#include pyml/EDITS.pyml
)[0];
$SCH_PL{ 'COBRATF' } = (
#include pyml/COBRATF.pyml
)[0];
$SCH_PL{ 'COUPLING' } = (
#include pyml/COUPLING.pyml
)[0];
$SCH_PL{ 'MPACT' } = (
#include pyml/MPACT.pyml
)[0];
$SCH_PL{ 'MAMBA' } = (
#include pyml/MAMBA.pyml
)[0];
$SCH_PL{ 'BISON' } = (
#include pyml/BISON.pyml
)[0];
$SCH_PL{ 'TIAMAT' } = (
#include pyml/TIAMAT.pyml
)[0];
$SCH_PL{ 'RUN' } = (
#include pyml/RUN.pyml
)[0];
#
# END REGULAR DEVELOPER SECTION
# Regular developers should not edit below.
#

# To have a bona fide XML file
my $XML_HEADER='<?xml version="1.0" encoding="UTF-8"?>';

#
# Process the command line
#
# my $_UPDATE='007';        # hidden updates
my $DEBUG=0;
my ($VERBOSE,$HELP,$VERSION);
my $XML='on';
my $XSLT='on';
my $NOTRIM;
my $INIT;
my $XINIT;
my $FOLLOW;
{ # process options
    GetOptions(
	"xml=s"     => \$XML,
	"xslt=s"    => \$XSLT,
	"verbose"   => \$VERBOSE,
	"debug"     => \$DEBUG,
	"version"   => \$VERSION,
	"help"      => \$HELP,
	"notrim"    => \$NOTRIM,
	"init"      => \$INIT,
	"xinit"     => \$XINIT,

	"fpath"     => \$FOLLOW          # hidden option for path following
#	"update=s"  => \$_UPDATE         # hidden updates
	);
}
(&help_print() && exit) if $HELP;;
if($VERSION){
    print STDERR "@VERSION\n";
    exit;
}

# if($_UPDATE eq '007'){        # hidden updates
#    $SCHEMA_PL{ASSEMBLIES} = "${directory}Templates/ASSEMBLIES007.yml";
#}

# For formatted display of XML file in a browser.
my $XSLT_FILE='PL9.xsl';
if($XSLT ne 'on' && $XSLT ne 'off'){
   $XSLT_FILE=$XSLT;
}
my $XSLT_HEADER="<?xml-stylesheet version=\"1.0\" type=\"text/xsl\" href=\"$XSLT_FILE\"?>";

my @ARGS=@ARGV;
if(@ARGS == 1){
    my($filename, $dirs, $suffix) = fileparse($ARGS[0],qr/\.[^.]*/);
    $ARGS[1]=$dirs.$filename.".xml";
}


if(@ARGS < 2){
    die "Usage: $pgnam [options ...] reactor_input_file output_xml_file
options:
  --xml=(on|off)
  --xslt=(on|off)
  --init
  --xinit
  --verbose
  --debug
  --version
  --help\n";
}

# Do not use initialization files for --xinit switch
unless($XINIT){
    foreach $iblock (@BLOCKS){
	my $finit="${directory}Init/${iblock}.ini";
	if ( -e $finit ) {
	    REACTOR::set_blockinit($iblock,$finit);
	    print STDERR "Found initialization block file $finit\n" if $VERBOSE;
	}
    }
}

#
# Initiate output blocks
#
foreach $iblock (@BLOCKS){
    $SCHEMA_PL{$iblock} = "${directory}Templates/$iblock.yml";
}


my ($ifile,$ofile)=@ARGS;

die "$pgnam: input file $ifile does not exist or not readable.\n"
    unless (-e $ifile && -r $ifile);
if(-e $ofile){
    die "$pgnam: files $ifile and $ofile files are the same\n"
	if filesame($ifile, $ofile);
}

# Follow file paths for include commands
if($FOLLOW){
    $fpath = abs_path($ifile);
    ($ifile, $FOLLOW) = fileparse($fpath);
    $FOLLOW = canonpath( $FOLLOW );
}

#
# Initiate configuration template for data structures
#

$INPUT_DB = (
#include pyml/Directory.pyml
)[0];

unless ( $INPUT_DB ){
    $YAML::UseAliases=0;    # minimize references
    ($INPUT_DB) = YAML::LoadFile( $SCHEMA );
# Clean up the inner references in the tree
# Need to fix in YAML package
    mergekeys_loop( $INPUT_DB );
}
#
# Initiate main directory tree for storage of input data
#
my $dref=key_exists($INPUT_DB,'_DIRECTORY');
$MAIN_DB=clone($dref);

#
# Turn on printing to STDERR in each of the packages
#
REACTOR->set_verbose()        if $VERBOSE;
REACTORBlock->set_verbose()   if $VERBOSE;
REACTORCommand->set_verbose() if $VERBOSE;
PL->set_verbose()             if $VERBOSE;
XMLPack->set_verbose()        if $VERBOSE;
Cellmaps->set_verbose()       if $VERBOSE;

#
# Initiate CASEID directly because it is the root node without block
# marker in input file
#
my $block=REACTORBlock->new( name=>'CASEID', inp_db=>$INPUT_DB, out_db=>$MAIN_DB );
$block->keyon();

#
# Read input file into main_db
#
read_ascii($ifile,$INPUT_DB,$MAIN_DB, 'follow'=>$FOLLOW);

print STDERR "\nFile $ifile read.\n\n"    if $VERBOSE;
YAML::DumpFile("$ifile.dbg.yml",$MAIN_DB) if $DEBUG;

#
# Process data from MAIN_DB and store it to
# separate trees for each of the PL blocks
#

# Associate the MAIN_DB data with the PL package
# To be used for multiple blocks of the same name in the future
# Currently, setting the main database in the PL yml files is
# just a placeholder for multiple blocks
PL->set_sourcedb($MAIN_DB);
# PL->dispatch($_UPDATE);        # hidden updates
PL->dispatch();

$YAML::UseAliases=0;    # minimize references
foreach $iblock (@BLOCKS){
    # Initiate each block
    unless( $SCH_PL{$iblock} ){
	($SCH_PL{$iblock}) = YAML::LoadFile( $SCHEMA_PL{$iblock} );
	mergekeys_loop( $SCH_PL{$iblock} );   # needs fix in YAML package
    }
    # Process the block using commands in the block templates
    PLlist($SCH_PL{$iblock}->{$iblock});
    YAML::DumpFile("$iblock.dbg.yml",$SCH_PL{$iblock}) if $DEBUG;
}

unless($NOTRIM){
    my $ilevel=0;
    foreach $iblock (@BLOCKS){
	PLtrim($SCH_PL{$iblock}->{$iblock},$ilevel);
    }
}
#
# XML output
#
open my($OFILE), '>', $ofile or die "$0: $! $ofile\n";

# Headers
unless($XML eq "off" && $XSLT eq "off"){
    print "Adding XML header ... $XML_HEADER\n" if $VERBOSE;
    print $OFILE "$XML_HEADER\n";
}
if($XSLT ne "off"){
    print "Adding XSLT header ... $XSLT_HEADER\n" if $VERBOSE;
    print $OFILE "$XSLT_HEADER\n";
}


# Select CASEID to be the root XML node
foreach $iblock (@BLOCKS){
    if($iblock eq 'CASEID'){
	packXMLlist($SCH_PL{$iblock}->{$iblock},$iblock,$OFILE,0,notclose=>1);
    }
    else{
	packXMLlist($SCH_PL{$iblock}->{$iblock},$iblock,$OFILE,1);
    }
}
# close the CASEID node
print $OFILE "</ParameterList>\n";

close $OFILE;

#
# User manual of sorts, will add pod
#
sub help_print{
    print STDERR <<EOF

Converts reactor input file (reactor_input_file) into ParameterList
XML file (output_xml_file). ParameterList format is defined in
Trilinos Teuchos package http://trilinos.sandia.gov/packages/teuchos/

Program errors messages indicate errors in the input file. More
verbose diagnostic messages are currently being added.

Program switches:

--help    This help.

--xml=(on|off)
          Write XML declaration as the first line of the ParameterList
          XML file. Default=on.

--xslt=(on|off)
          Write XSLT processing instruction as the second line of the
          ParameterList XML file. Turns on --xml switch, as well. XSLT
          style file PL9.xsl should be in the same directory as the
          resulting ParameterListXML file in order for transofrmation
          to work in a browser. See additional information in
          "User-Friendly Formatting of VERA Input" on CASL
          Wiki. Default=on.

--verbose Add processing printouts as the code executes.

--debug   Create debug files for finding the errors in the converter
          program. Does not help much in tracing invalid input.

EOF
}
