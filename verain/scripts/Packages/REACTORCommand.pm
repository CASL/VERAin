package REACTORCommand;
use Carp;
use Text::ParseWords;

use Data::Types qw(:all);
use List::MoreUtils::PP;

use REACTORBlock;

use KeyTree;
use MiscUtils;
use TypeUtils;


{
    my $_count = 0;
    sub get_count {$_count;}
    sub _incr_count { ++$_count }
    sub _decr_count { --$_count }

    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }

    my $_DEBUG = 0;
    sub get_debug  {$_DEBUG;}
    sub set_debug { $_DEBUG = 1; }
}

sub new
{
    my ($class, %arg) = @_;

    my $self={
	keyword => $arg{keyword} || croak("missing keyword"),
	keytree => $arg{keytree} || croak("missing keytree"),
	out_db  => $arg{out_db}  || croak("missing out_db"),

	ctext   => exists($arg{ctext})   ? $arg{ctext}  : undef,
	tlist   => exists($arg{tlist})   ? $arg{tlist}  : undef,

	id      => exists($arg{id})      ? $arg{id}  : undef,
	idx     => exists($arg{idx})     ? $arg{idx}  : undef,

	defpath => exists($arg{defpath}) ? $arg{defpath}: undef,
	defval  => exists($arg{defval})  ? $arg{defval} : undef,

	file    => exists($arg{file})    ? $arg{file}   : undef,
	line    => exists($arg{line})    ? $arg{line}   : undef,
    };

    bless $self, $class;
}

sub ctokens
{
    my ($self,$idx)=@_;
    my $myfun=(caller(0))[3];

    my @a;
#   Split the command text into tokens
    unless(defined($self->{tlist})){
	my $dtx=$self->ctext();
	if($self->argexists('_slash')){
	    $dtx =~ s/\// \/ /g;
	}
	my $split_exp='\s+|=';
	@a=quotewords($split_exp, 0, $dtx);
	@a = grep {defined && $_ ne ''} @a;
	unless($self->argexists('_slash')){
	    @a = grep {defined && $_ ne '/'} @a;
	}
	foreach my $data (@a){
	    txt2xml(\$data);
	}
	$self->{tlist}=\@a;
    }

    if(@_ > 1){
	my $n=splice(@{ $self->{tlist} },$idx-1,1);
	croak "Bad index $idx to $myfun" unless defined($n);
    }

    return @{ $self->{tlist} };
}

sub defaults
{
    my ($self,$aref)=@_;
    my $myfun=(caller(0))[3];

    my $defpath = $self->argvalue('_defaults','_path');
    my $defval  = $self->argvalue('_defaults','_value');

    my $line=$self->line();
    my $file=$self->file();
    my $dtx =$self->ctext();

    if($defpath){ # TODO: logic for defval
	my $keyword=$self->keyword();
	my $id=$self->id();

	$defpath =~ s/\(_keyword\)/$keyword/g;
	$defpath =~ s/\(_id\)/$id/g if defined($id);
	$self->defpath($defpath);
	$self->defval($defval) if(defined($defval));

	my @path=parse_path($defpath);
	my $SOURCE_DB=$self->out_db();
	my $t=key_defined($SOURCE_DB,@path);

	# TODO: hardwired for array
	return undef if ref $t ne 'ARRAY';
	
	my @b=@{ $t };
	my @a=$self->ctokens();
	my @b0=@b;

	my $done;
	my @opta;
	my @optb;
	for ($keyword) {
	    if (/^mat$/) { # Andrew's logic for mats, will need to be
			   # moved to separate sub if other commands
			   # are to have have options

		if($self->argexists('_options')){
		    @opta=extract_options(\@a); # save options of a, remove them from a
		    @optb=extract_options(\@b); # save options of b, remove them from b
		}

		@a != 1 && do {
		    @b=@a;
		    $done='mat overwrite';
		    append_options(\@b,@opta) if @opta;
		    last;}; # a has new definition, erase old
		@a == 1 &&
		(($b[0] == 0 && $a[0] != 0) || 
		 ($b[0] != 0 && $a[0] == 0)) && do {
		     &error_report($keyword,$dtx,$file,$line,
				   "Incompatible densities: default $b[0], new $a[0]");
		     die "$myfun illegal switch of material densities\n";
		};
		@a == 1 && do { # a inherits definition of b, erase old b density with a
		    $b[0]=$a[0];
		    append_options(\@b,@opta) if @opta;
		    append_options(\@b,@optb) unless @opta;
		    $done='mat density';
		    last;};
	    }
	    else{ # default, everything except mat: overwrite b with a as far a goes
		$done='default';
		for(my $i=0; $i<@a; $i++){
		    $b[$i]=$a[$i];
		}
		last;
	    }
	}

	print "result: $done [@b0][@a] ===> [@b]\n"  if get_verbose();
	$self->{tlist}=\@b;
    }
}

sub argexists
{
    my ($self,@argument)=@_;
    my $myfun=(caller(0))[3];

    croak "Too few arguments to $myfun" if @_ < 2;

    my $tree=$self->keytree();
    return key_exists($tree,@argument);
}

sub argvalue
{
    my ($self,@argument)=@_;
    my $myfun=(caller(0))[3];

    croak "Too few arguments to $myfun" if @_ < 2;

    my $tree=$self->keytree();
    return key_defined($tree,@argument);
}

sub is_multiline
{
    my ($self)=@_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 1;

    my $keyw_style=$self->argvalue('_style') || 0;
    if($keyw_style eq 'multi-line'){
	return 1;
    }
    return 0;
}

sub argarray
{
    my ($self,@argument)=@_;
    my $myfun=(caller(0))[3];

    croak "Too few arguments to $myfun" if @_ < 2;

    my $tree=$self->keytree();
    return values_at($tree,@argument);
}

sub argkeys
{
    my ($self,@argument)=@_;
    my $myfun=(caller(0))[3];

    croak "Too few arguments to $myfun" if @_ < 2;

    my $tree=$self->keytree();
    my $ref=key_exists($tree,@argument);
    return (ref $ref eq 'HASH') ? keys_at($ref) : ();
}

sub ctext
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{ctext} .= " ".$newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{ctext});
    return $self->{ctext};
}

sub ctextwrite
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Invalid number of arguments to $myfun" if @_ != 2;
    $self->{ctext} = $newval;
    croak "$myfun undefined entry" unless defined($self->{ctext});
    return $self->{ctext};
}

sub file
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{file}= $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{file});
    return $self->{file};
}

sub line
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{line}= $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{line});
    return $self->{line};
}

sub keytree
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{keytree} = $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{keytree});
    return $self->{keytree};
}

sub keyword
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{keyword} = $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{keyword});
    return $self->{keyword};
}

sub out_db
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{out_db}= $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{out_db});
    return $self->{out_db};
}

sub defpath
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{defpath}= $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{defpath});
    return $self->{defpath};
}

sub defval
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{defval}= $newval if @_ > 1;
    croak "$myfun undefined" unless defined($self->{defval});
    return $self->{defval};
}

sub id
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{id}= $newval if @_ > 1;
    return $self->{id};
}

sub idx
{
    my ($self, $newval) = @_;
    my $myfun=(caller(0))[3];

    croak "Too many arguments to $myfun" if @_ > 2;
    $self->{idx}= $newval if @_ > 1;
    return $self->{idx};
}

sub cleanline ($$$) {
    my $lineref=shift;
    my $what=shift;
    my $with=shift;

    $$lineref =~ s/$what/$with/g;
}

sub keyin{
    my $self=shift;
    my $myfun=(caller(0))[3];

    my ($name_idx, $name);
    my $result;
    my $errmsg;

    my $dtx=$self->ctext();
    my $dtxs;
    my $line=$self->line();
    my $file=$self->file();

    my $REF_LABEL='_key';
    my $CONTENT_LABEL='_content';
    my $FILE_LABEL='_file';
    my $LINE_LABEL='_line';

    my $templ=$self->keytree();
    my @sr=$self->argarray('_check');
    my $parse = $self->argvalue('_parse');
    my $type = $self->argvalue('_type');

# extract parameters if exist
    my %CPARMS;
    $self->extract_parameters(\%CPARMS);
#   Split the command text into tokens
    my @a=$self->ctokens();
    my @a0=@a;

# redefining reference if the keyword is named
    $name_idx=$self->argvalue('_named');
    if($name_idx){
	$name=$a[$name_idx-1];
	unless(defined($name)){
	    &error_report($self->keyword(),$dtx,$file,$line,$errmsg);
	    die "keyin: named parameter does not have key name defined.\n";
	}
	$self->id($name);
	$self->idx($name_idx);
	@a=$self->ctokens($name_idx);

	$templ=new_key($templ,$REF_LABEL,$name);
    }

# run defaults 
    $self->defaults();
    @a=$self->ctokens();

#   Run checks and keyon data
    $result=0;
    if($parse eq 'scalar'){
	# Also works with named scalar string that is not allowed yet
	if($type eq 'string'){
#	    txt2xml(\$dtx);
	    if(@a){
		$dtxs=join(' ',@a);
	    }
	}
	else{
	    $dtxs=$a[0];
	}
	$result=&apply_evals(\$dtxs,\@sr,\$errmsg,$self);
	key_on($templ,$CONTENT_LABEL,$dtxs) if $result;
    }
    elsif($parse eq 'list'){
	$result=&apply_evals(\@a0,\@sr,\$errmsg,$self);
	key_on($templ,$CONTENT_LABEL,[@a]) if $result;
    }
    else{
	croak "$myfun invalid parse type";
    }
    unless($result){
	&error_report($self->keyword(),$dtx,$file,$line,$errmsg);
	die "$myfun command check fail\n";
    }

    $result=$self->encode_parameters(\%CPARMS,$templ,\$errmsg);
    unless($result){
	&error_report($self->keyword,$dtx,$file,$line,$errmsg);
	die "$myfun parameter check fail\n";
    }

    return $result;
}

sub error_report
{
    my ($command,$text,$file,$line,$error)=@_;

    print STDERR "Error in $file line $line:\n";
    print STDERR "    Keyword: [$command]\n";
    print STDERR "    String : [$command $text]\n";
    print STDERR "    Error  : [$error]\n";
}

sub apply_evals {
    my ($data_ref,$eval_ref,$errmsg_ref,$command)=@_;
    my $ieval;
    my $dtype=ref $data_ref;

    my $keyword=$command->keyword();
    my $id=$command->id();
    my $out_db=$command->out_db();

    foreach $ieval (@{$eval_ref}){
	$$errmsg_ref="$ieval";
	if($ieval=~ m/(error>)(.*)/){
	    $$errmsg_ref=$2;
	    substr( $ieval, $-[2], $+[2], '' );
	    substr( $ieval, $-[1], $+[1], '' );
	}
	$ieval =~ s/^\s+//;
	$ieval =~ s/\s+$//;
	return 1 unless $ieval;

	my @cargs=split(/\s+/,$ieval);
#	print "ieval $ieval\n";
#	my @cargs=quotewords('\s+', 0, $ieval);


	my $cmdc=shift(@cargs);
	if($dtype eq 'SCALAR'){
	    unshift @cargs,$$data_ref;
	}
	elsif($dtype eq 'ARRAY'){
	    unshift @cargs,@{ $data_ref };
	}
	else{
	    die "apply_evals: error in data_ref $ieval\n";
	}
	@cargs=map { "\"$_\"" } @cargs;
	my $exa=join(',',@cargs);
	print STDERR "--------- check $dtype: [$ieval]\n" if get_verbose();;
	$cmdc =~ s/\(\)/\($exa\)/g;
	$cmdc =~ s/\[\]/\[$exa\]/g;

	$cmdc =~ s/\(_keyword\)/$keyword/g;
	$cmdc =~ s/\(_id\)/$id/g if defined($id);

	my $expr="$cmdc";
	print STDERR "--------------- $expr\n" if get_verbose();;
	my $result=eval $expr || 0;
	print STDERR "--------------- result $result\n" if get_verbose();;

	if(!$result){
	    print STDERR "------------------- error: $$errmsg_ref\n" if get_verbose();;
	    return 0;
	}

    }
    return 1;
}

sub extract_parameters {
    my ($self,$href)=@_;
    my $myfun=(caller(0))[3];

    my @pa=$self->argkeys('_parameters');
    if(@pa){
	my %validk;
	@validk{@pa} = ();
	my $keyw=$self->keyword();
	my $dtx=$self->ctext();
	my $slcnt = times_in_string( '\/', $dtx);
	return if $slcnt < 1;
	my $loc = rindex($dtx, '/');
	if($loc>0){
	    my ($pre, $post) = split_string_at($dtx,$loc);
	    $pre =trim_space($pre);
	    $post=trim_space($post);
	    $self->ctextwrite($pre);

	    my @para=match_all_equalities($post);
	    foreach my $ipara ( @para ){
		my ($kk1, $kk2)=@{ $ipara };
#		print "para [$kk1] [$kk2]\n";
		if(exists($validk{$kk1})){
		    $href->{$kk1}=$kk2;
		}
		else{
		    my $line=$self->line();
		    my $file=$self->file();
		    my $errmsg = "invalid parameter $kk1";
		    &error_report($keyw,$dtx,$file,$line,$errmsg);
		    die "Input syntax error\n";
		}
	    }
	}
    }
}

sub encode_parameters {
    my ($self,$href,$templ,$referrmsg)=@_;
    my $myfun=(caller(0))[3];

    my $split_exp='\s+';
    my $result=1;
    my $LABEL='_parameters';
    my $CONTENT_LABEL='_content';

    foreach my $ikey ( keys %{ $href } ){
	$result=0;
	my @sr    = $self->argarray($LABEL,$ikey,'_check');
	my $parse = $self->argvalue($LABEL,$ikey,'_parse');
	my $type  = $self->argvalue($LABEL,$ikey,'_type');
	my $named = $self->argvalue($LABEL,$ikey,'_named');
#	print "key: $ikey, parse: $parse, type: $type, check: @sr, named: $named\n";
	if($named){
	    print STDERR "Named parameter $ikey is not allowed in parameters.\n";
	    die "Internal configuration error, invalid Directory.yml entry.\n";
	}

	my $pvalue=$href->{$ikey};
	my $tp=new_key($templ,$LABEL,$ikey);

	if($parse eq 'scalar'){
	    $result=&apply_evals(\$pvalue,\@sr,$referrmsg,$self);
	    key_on($tp,$CONTENT_LABEL,$pvalue) if $result;
	}
	elsif($parse eq 'list'){
	    my @a=quotewords($split_exp, 0, $pvalue);
	    @a = grep {defined && $_ ne ''} @a;
	    $result=&apply_evals(\@a,\@sr,$referrmsg,$self);
	    key_on($tp,$CONTENT_LABEL,[@a]) if $result;
	}
	else{
	    print STDERR "Invalid parse type for parameter $ikey.\n";
	    die "Internal configuration error, invalid Directory.yml entry.\n";
	}
	return $result unless $result;

	my $pw='%ASSEMBLY/$path/%axial/@loop^';
	my @aa=parse_path( $pw );
#	print "aa: @aa\n";
	
    }
    return $result;
}

1;
