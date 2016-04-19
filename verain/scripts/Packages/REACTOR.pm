package REACTOR;

use KeyTree;
use MiscUtils;
use TypeUtils;
use Cellmaps;

use REACTORBlock;
use REACTORCommand;

# use Clone qw(clone);
# use ClonePP qw(clone);
use Clone::PP qw(clone);

use Data::Types qw(:all);
use List::MoreUtils::PP;

use Text::Balanced qw (
                        extract_delimited
                        extract_bracketed
                       );
use List::Maker 'range';
use Text::ParseWords;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('read_ascii');

# for initialization of every block
# it gets used on every invocation of new block
our %BLOCKINIT=();

our $block;
our $command;

{
    sub set_blockinit { $BLOCKINIT{$_[0]} = $_[1]; }

    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }

    my $_DEBUG = 0;
    sub get_debug  {$_DEBUG;}
    sub set_debug { $_DEBUG = 1; }

    my $_FILE;
    my $_INPUT_LINE_NUMBER;
    my $_INPUT_LINE;
    sub set_input_log {($_FILE,$_INPUT_LINE_NUMBER,$_INPUT_LINE)=@_;}
    sub print_input_log {
	print STDERR "Last input line [$_FILE] $_INPUT_LINE_NUMBER: $_INPUT_LINE\n";
    }

}

sub clean_line{
    my $lineref=shift;

    my $text=$$lineref;
    my $transl;

    while( $text =~ m/(['"<!])/g ){   # search for quote marks
	my $delim=$1;
	my $loc2=pos($text);             # found quote mark location + 1
	pos($text)= $loc2-1;          # set position to the quote mark
	my $dist=$loc2-1;       # distance from the previous location to quote
	my $next;
	my $rest;

	$dist && do{
	    my $pfx=substr($text, 0, $dist);            # string before the quote mark, prefix
	    $pfx =~ s/(\d+)\s*\*\s*(\w+)/"$2 " x $1/ge; # expand fortran expressions
	    $transl.=$pfx;                              # append prefix to the result
	};

	if($delim eq '<'){
	    ($next,$rest) = extract_bracketed($text,'<');
	    unless($next){
		die "clean_line: Unbalanced brackets: $text\n";
	    }
	    $next =~ s/^.//; $next =~ s/.$//; # strip angle brackets
	    my @ary=();
	    @ary = range( $next );
	    unless($next){
		die "clean_line: Nothing generated with range: $text\n";
	    }
	    $transl.=" @ary ";
	}
	elsif($delim eq '!'){
	    $text='';
	    last;
	}
	else{
	    ($next,$rest) = extract_delimited($text,"$delim");
	    unless($next){
		die "clean_line: Unbalanced quotes: $text\n";
	    }
	    $transl.=$next;
	}
	$text=$rest;
    }

    if(defined($transl)){
	$transl.=$text;
    }
    else{
	$transl=$text;     # there were no quotes nor comments in the string
	$transl =~ s/(\d+)\s*\*\s*(\w+)/"$2 " x $1/ge; # expand fortran expressions
	$transl =~ s/[,]/ /g;               # remove commas and such
    }
    $transl=~s/^\s+//;           # just in case
    $transl=~s/\s+$//;
    $transl=~s/(\[\s*\w+\s*\])/$1 ;/g;

    $$lineref=$transl;
    return;
}

sub read_ascii {
    my ($filename, $INPUT_DB, $MAIN_DB, %userparam) = @_;
    my ($cname,$ctext);
    my ($name,$res);

    my $incl = 0;
    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$key eq 'incl'   && do {$incl=$value;};     # include flag
    }

    my($IFILE); 
    if (-f $filename){
      print STDERR "Opennng file with name: $filename\n" if get_verbose();
      open $IFILE, $filename or ( &print_input_log() &&  die "Cannot open file $filename\n");
    }
    else{
      use Cwd 'abs_path';
      use File::Basename;
      my $pscript=abs_path($0);
      my $directory = dirname($pscript);
      my $filename2="$directory/Init/$filename";
      if (-f $filename2){
        print STDERR "Opennng file with path: $filename2\n" if get_verbose();
        open $IFILE, $filename2 or ( &print_input_log() && die "Cannot open file $filename2\n" );
      }
      else{
        &print_input_log();
        die "$filename2 does not exist\n";
      }
    }

  READ: while (<$IFILE>) {       # main read loop
      s/^\s+//;
      s/\s+$//;
      next READ if /^$/;        # skip empty lines
      &set_input_log($filename,$.,$_);
      &clean_line(\$_);

      my $split_exp=';';
      my @comms=quotewords($split_exp, 1, $_);

      foreach ( @comms ){
	  s/^\s+//;
	  s/\s+$//;
	  next if /^$/;        # skip empty lines

	  /^include\s+(\S+)/ && do{
	      my $ifile=$1;
	      print STDERR "[$filename:$.] Include file: $ifile\n" if get_verbose();
	      read_ascii($ifile,$INPUT_DB, $MAIN_DB, 
			 'incl'=>1);
	      next;
	  };

	  /^\[\s*(.*)?\s*\](.*)/ &&     # found new block
	      do{
		  $name=$1;
		  my $rest=$2;
		  die "Error on block definition: $_.\n" if $rest;
		  if($block){        # old block that needs to be put into the main tree
		      if($command){  # old command to complete
			  print STDERR "[$filename:$.] End command on new block: ", $command->keyword(), ": ", $command->ctext(), "\n"  if get_verbose();
			  $command->keyin();
			  $command=undef;
		      }
		      print STDERR "[$filename:$.] End block: ", $block->name(), "\n"  if get_verbose();
		      $block->keyon();
		      $block=undef;
		  }
		  print STDERR "[$filename:$.] New block: $name\n"  if get_verbose();
		  die "[$filename:$.] Bad block name.\n" unless key_exists($INPUT_DB,$name);
		  $block=REACTORBlock->new( name=>$name, out_db=>$MAIN_DB );
		  $block->inp_db($INPUT_DB);  # INPUT_DB is root of Directory.yml

		  if(exists($REACTOR::BLOCKINIT{$name})){
		      print STDERR "Initialize block $name with file $BLOCKINIT{$name}\n" if get_verbose();
		      read_ascii($REACTOR::BLOCKINIT{$name}, $INPUT_DB, $MAIN_DB, 'incl'=>1);
		  }

		  $command=undef;
		  next;
	  };
	  $block && !$command && do{   # block previously initialized, but no commands yet.
	      /^(\S+)\s*(.*?)$/ && do{ # check if the first line is a command
		  $cname=$1;
		  $ctext=($+[2]-$-[2]) ? $2 : '';
		  $res=$block->is_command($cname) || 0;
		  die "[$filename:$.] invalid keyword $cname in block ", $block->name(), "\n" unless $res;
		  print STDERR "[$filename:$.] New command: $cname $ctext\n"  if get_verbose();
		  $cname=$block->command_name($cname);
		  $command=REACTORCommand->new(keyword=>$cname,keytree=>$res,out_db=>$MAIN_DB,
					       ctext=>$ctext,file=>$filename,line=>$.);
		  unless($command->is_multiline()){
		      print STDERR "[$filename:$.] End command on single line: ", $command->keyword(), ": ", $command->ctext(), "\n"  if get_verbose();
		      $command->keyin();
		      $command=undef;
		  }
		  next;
	      };
	  };
	  $block && $command && do{    # new block initialized, multi-line command already started
	      /^(\S+)\s*(.*)$/ && do{  # check if the new entry is a command
		  $cname=$1;
		  $ctext=($+[2]-$-[2]) ? $2 : '';
		  $res=$block->is_command($cname) || 0;

		  if($res){   # complete old command
		      print STDERR "[$filename:$.] End command on new command: ", $command->keyword(), ": ", $command->ctext(), "\n"  if get_verbose();
		      $command->keyin();
		      $command=undef;

		      print STDERR "[$filename:$.] New command: $cname $ctext\n"  if get_verbose();
		      $cname=$block->command_name($cname);
		      $command=REACTORCommand->new(keyword=>$cname,keytree=>$res,out_db=>$MAIN_DB,
						   ctext=>$ctext,file=>$filename,line=>$.);
		      unless($command->is_multiline()){
			  print STDERR "[$filename:$.] End command: ", $command->keyword(), ": ", $command->ctext(), "\n"  if get_verbose();
			  $command->keyin();
			  $command=undef;
		      }
		      next;
		  }
	      };
	      $command->ctext($_); # if not a new command, keep accumulating
	  };
      }  # end of multiple command loop
  }
    # file ended, check for uncompleted commands
    if($command){
	print STDERR "[$filename:$.] End command on file exit: ", $command->keyword(), ": ", $command->ctext(), "\n"  if get_verbose();
	$command->keyin();
	$command=undef;
    }

    # file ended, close last block if main file
    if($block && $incl == 0){
	print STDERR "[$filename:$.] End block on end of input: ", $block->name(), "\n"  if get_verbose();
	$block->keyon();
	$block=undef;
    }

    return 1;
}
    

1;
