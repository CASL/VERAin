package KeyTree;

use Carp  qw(cluck);;
use Data::Dumper ;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('new_key',
	 'key_exist',
	 'key_exists',
	 'key_defined',
	 'push_on',
	 'key_on',
	 'key_hash_assign',
	 'read_off_size',
	 'key_on_counted',
	 'key_on_mapped',
	 'read_off_counted',
	 'read_off_mapped',
	 'read_off_map_key',
	 'read_off_label',
	 'read_off_label_key',
	 'read_keys_labels',
	 'read_keys',
#	 'walk_print',
	 'purge',
	 'counter',
	 'parse_path',
	 'find_keys',
	 'keys_at',
	 'values_at',
	 'value_eq_at',
	 'key_delete',
	 'find_defined'
    );

my $DIE_ON_UNDEF=1;

{
    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }
}


#used
sub new_key { # initialize tree node, return pointer to the node
    my ($ref,@keys)=@_;
    
    foreach (@keys){
	unless(exists($ref->{$_})){
#	unless(defined($ref->{$_})){
	    keys(%{ $ref->{$_} }); # initialize hash by vivification
#	    $ref->{$_} =undef;
	}
	$ref=\%{ $ref->{$_} };
#	$ref=$ref->{$_};
    }
#    print Data::Dumper->Dump([$ref], [qw(ref)]);
    return $ref;
}

sub key_hash_assign {
    my( $ref_ref, $val, @keys ) = @_ ;
    unless ( @keys ) {
	warn "key_hash_assign: no keys" ;
	return undef;
    }
    foreach my $key ( @keys ) {
	my $ref = ${$ref_ref} ;
	# this is the autoviv step
	unless ( defined( $ref ) ) {
	    $ref = { $key => undef } ;
	    ${$ref_ref} = $ref ;
	}
	# this checks we have a valid hash ref as a current value
	unless ( ref $ref eq 'HASH' and exists( $ref->{ $key } ) ) {
	    warn "key_hash_assign: not a hash ref at $key in @keys" ;
	    return undef;
	}
	# this points to the next level down the hash tree
	$ref_ref = \$ref->{ $key } ;
    }
    ${$ref_ref} = $val ;
    return 1;
}

sub key_defined {           # will return actual value if it is a leaf with a value
    my( $ref, @keys ) = @_ ;
    unless ( @keys ) {
	warn "key_defined: no keys" ;
	return undef;
    }
    foreach my $key ( @keys ) {
	if( ref $ref eq 'HASH' ) {
	    # fail when the key doesn't exist at this level
	    unless(defined( $ref->{$key} )){
#		warn "key_defined: key doesn't exist at $key\n";
		return undef;
	    }

	    $ref = $ref->{$key} ;
	    next;
	}
	if( ref $ref eq 'ARRAY' ) {
	    # fail when the index is out of range or is not defined
	    unless(0 <= $key && $key < @{$ref}){
#SSMODfix:w/ErrorHandler		die "key_defined: index out of range\n";
		return undef;
	    }
	    unless(defined( $ref->[$key] )){
		die "key_defined: array not defined\n";
		return undef;
	    }
	    $ref = $ref->[$key] ;
	    next;
	}
	# fail when the current level is not a hash or array ref
	die "key_defined: current level $key is not a hash or array ref\n";
	return undef;
    }
    return $ref;
}

#used
sub key_exist { # return ref if key exists, otherwise return undef
    my ($ref,@keys)=@_;

    foreach (@keys){
	unless(exists($ref->{$_})){
	    return undef;
	}
	$ref=\%{ $ref->{$_} };
#	$ref=$ref->{$_};
    }
    return $ref;
}

sub key_exists {
    my( $hash_ref, @keys ) = @_ ;
    unless ( @keys ) {
	warn "key_exists: no keys" ;
	return $hash_ref;
    }
    foreach my $key ( @keys ) {
	unless( ref $hash_ref eq 'HASH' ) {
	    warn "key_exists: $hash_ref not a HASH ref" ;
	    return undef;
	}
	return undef unless exists( $hash_ref->{$key} ) ;
	$hash_ref = \%{ $hash_ref->{$key} };
#	$hash_ref = $hash_ref->{$key};
    }
    return $hash_ref;
}

sub key_delete {
    my( $hash_ref, @keys ) = @_ ;
    my $last_hash;
    my $last_key;

    print "key_delete: @keys\n";

    unless ( @keys ) {
	warn "key_delete: no keys" ;
	return $hash_ref;
    }
    foreach my $key ( @keys ) {
	unless( ref $hash_ref eq 'HASH' ) {
	    warn "key_delete: $hash_ref not a HASH ref" ;
	    return undef;
	}
	return undef unless exists( $hash_ref->{$key} ) ;

	$last_hash= $hash_ref;
	$last_key=$key;

	$hash_ref = \%{ $hash_ref->{$key} };


#	$hash_ref = $hash_ref->{$key};
    }

    delete $last_hash->{$last_key};
    print "deleted $last_hash $last_key\n";
    return;
}

sub keys_at {
    my( $hash_ref ) = @_ ;

    unless( ref $hash_ref eq 'HASH' ) {
	warn "keys_at: $hash_ref not a HASH ref" ;
	return undef;
    }
	
    return keys %{ $hash_ref };
}

sub array_at {
    my( $ref ) = @_ ;

    unless( ref $ref eq 'ARRAY' ) {
	warn "array_at: $ref not an ARRAY ref" ;
	return undef;
    }
	
    return @{ $ref };
}

sub values_at{
    my( $ref, @path) = @_ ;
    my @values;

    my $refN=key_defined( $ref, @path);
    if( ref $refN eq 'ARRAY' ) {
	@values=@{$refN};
	return @values;
    }
    else{
	return;
    }
}

sub value_eq_at{
    my( $ref, $cmpvalue, @path) = @_ ;
    my $value;

    my $refN=key_defined( $ref, @path);
    if( !ref($refN) ){
	$value=$refN;
	return unless $value eq $refN;
	return 1;
    }
    else{
	die "value_eq_at: invalid reference type", ref($refN), "\n";
    }
}

sub parse_path{
    my ($path)=@_;

    my $valid_name=qr/[\w]+[\w-.]*/;
    $path=~s/\%($valid_name)/$1\/_key/g;

    $path=~s/\@($valid_name)\^/$1\/_parameters/g;
    $path=~s/\@($valid_name)/$1\/_content/g;
    $path=~s/\:(\d+)/\/$1/g;

#    $path=~s/\$([^\/]+)/$1\/_content/g;

    $path=~s/\$($valid_name)\^/$1\/_parameters/g;
    $path=~s/\$($valid_name)/$1\/_content/g;

    $path=~s/\$\//_content\//g;
    my @a=split /\//, $path;

    if($a[0] eq ''){shift @a};
    if($a[$#a] eq ''){pop @a};
    return @a;
}

sub find_keys {
    my( $ref, $path, $fkey, %userparam ) = @_ ;
    my @loop;
    my $ipath;
    my %OPTIONS;

    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$OPTIONS{$key}=$value;
    }

    $fkey='*' unless defined $fkey;

    my @a=split /\*/, $path;
    my $path0=shift @a;
    my @path0=parse_path($path0);
    my $ref0=key_defined( $ref, @path0);

    if( ref $ref0 eq 'HASH' ) {
	@loop=keys(%{$ref0});
#	print "path0: $path0\n";
#	print Dumper($ref0);
#	print "path0: [@path0]\n";
#	print "find keys: @loop\n";

    }
    elsif( ref $ref0 eq 'ARRAY' ) {
	@loop=(0..$#{$ref0});
    }
    else{
	return ();
#	die "find_keys 1 [@path0]: reference $ref0 is not valid\n";
    }

    my @pathlist=();
    my @newpathlist=();
    foreach (@loop){
	push @pathlist, [@path0,$_];
    }

    for(my $i=0;$i<@a;$i++){
	my @pathN=parse_path($a[$i]);      # get new segment form path string
	foreach $ipath (@pathlist){        # loop over found paths
	    my @pathfind=(@{$ipath},@pathN);
	    my $refN=key_defined( $ref, @pathfind);

	    if( ref $refN eq 'HASH' ) {
		@loop=keys(%{$refN});
	    }
	    elsif( ref $refN eq 'ARRAY' ) {
		@loop=(0..$#{$refN});
	    }
	    else{
		print "find_keys: loop: @loop\n";
		print "find_keys: path0: @path0\n";
		print "find_keys: pathfind: @pathfind\n";
		die "find_keys: 2 [@pathN]: reference $refN is not valid\n";
	    }
	    foreach (@loop){
		push @newpathlist, [@pathfind,$_];
	    }
	}
	@pathlist=@newpathlist;
    }

    my @outstring=();
    my @outarray=();
    foreach $ipath (@pathlist){
	my $value=$ipath->[$#{$ipath}];
	if($fkey eq '*' || $fkey eq $value){
	    push @outstring, join('/',@{$ipath});
	    push @outarray, [@{$ipath}];
	}
    }

    if(exists($OPTIONS{strings}) && $OPTIONS{strings} eq 'true'){
	return @outstring;
    }
    else{
	return @outarray;
    }
}


#used
sub push_on { # push an array onto node
    my ($ref, $label, @data)=@_;

    push @{ $ref->{$label} }, @data;
}

#used
# add mapped hash onto node
# retreive it as $ref=read_off_label and use each %{ $ref }
sub key_on {
    my ($ref, %hash)=@_;
    my $k;
    my $v;

    while (($k,$v) = each(%hash)){
	$ref->{$k}=$v;
    }
}

#used
sub read_off_size { # reads size of stored hash
    my ($ref)=@_;
    my $n;

    $n=defined($ref) ? 
	keys (%{ $ref }) : 
	$DIE_ON_UNDEF ? 
	cluck "@_\n" : undef;
    
    return $n;
}

#used
sub read_keys_labels { # return keys of level described by labels
    my ($ref,@labels)=@_;
    my @keys;

    my $loc=key_exist($ref,@labels);
    if($loc && ( ref $loc eq 'HASH' )){
	@keys=keys %{ $loc };
	return @keys;
    }
    else{
	cluck "@_\n" if $DIE_ON_UNDEF;
	return undef;
    }
}

sub read_keys { # return keys of the has on the given reference level
    my ($ref)=@_;
    my @keys;

    if (ref $ref eq 'HASH') {
	@keys=keys %{ $ref };
	return @keys;
    }
    else{
	cluck "@_\n" if $DIE_ON_UNDEF;
	return undef;
    }
}

#used
sub read_off_counter { # reads size of stored counted hash
    my ($ref, $counter)=@_;
    my $n;

    $n=exists($ref->{$counter}) ? $ref->{$counter} : undef;
    cluck "@_\n" if $DIE_ON_UNDEF && !defined($n);
    return $n;
}

#used
# add mapped hash onto node
# retreive it as $ref=read_off_label and use each %{ $ref }
sub key_on_counted {
    my ($ref, $counter, %hash)=@_;
    my $k;
    my $v;

    while (($k,$v) = each(%hash)){
	unless(exists($ref->{$k})){
	    $ref->{$counter}++;
	}
	$ref->{$k}=$v;
    }
}

#used
sub key_on_mapped { # add mapped hash onto node
    my ($ref, $label, $map_label, $counter, %hash)=@_;
    my $k;
    my $v;
    my $id;

    while (($k,$v) = each(%hash)){
	unless(exists($ref->{$label}->{$k})){
	    $ref->{$counter}++;
	    $id=$ref->{$counter};
	    $ref->{$map_label}->{$id}=$k;
	    $ref->{$label}->{$k}->[0]=$id;
	}
	$ref->{$label}->{$k}->[1]=$v;
    }
}

#used
sub read_off_mapped { # add mapped hash onto node
    my ($ref, $label, $map_label, $map_id)=@_;
    my $v;
    my $k;

    $k=exists($ref->{$map_label}->{$map_id}) ? 
	$ref->{$map_label}->{$map_id} : undef;
    cluck "at k ($k) @_\n" if $DIE_ON_UNDEF && !defined($k);
    $v=exists($ref->{$label}->{$k}->[1]) 
	? $ref->{$label}->{$k}->[1] : undef;
    cluck "at v ($v) @_\n" if $DIE_ON_UNDEF && !defined($v);
    return $v;
}

#used
sub read_off_map_key { # add mapped hash onto node
    my ($ref, $label, $k)=@_;
    my $v;

    $v=exists($ref->{$label}->{$k}->[0]) ? 
	$ref->{$label}->{$k}->[0] : undef;
    cluck "at v ($v) @_\n" if $DIE_ON_UNDEF && !defined($v);
    return $v;
}

#used
sub read_off_label { # read reference of label
    my ($ref, $label)=@_;
    my $v;

    $v=exists($ref->{$label}) ? $ref->{$label} : undef;
#    cluck "at v ($v) @_\n" if $DIE_ON_UNDEF && !defined($v);
    return $v;
}

#used
sub read_off_label_key { # read reference of label and key
    my ($ref, $label, $k)=@_;
    my $v;

    $v=exists($ref->{$label}->{$k}) ? $ref->{$label}->{$k} : undef;
    cluck "at v ($v) @_\n" if $DIE_ON_UNDEF && !defined($v);
    return $v;
}

sub walk_print {
    # item  - reference to tree node
    # path  - reference to array
    # depth - depth counter
    my ($item, $path, $depth) = @_;
    if (ref $item eq 'ARRAY') {
        foreach (@$item) {
            walk_print($_, $path, $depth);
        }
    } elsif (ref $item eq 'HASH') {
	$depth++;
        foreach (keys %$item) {
            push @$path, $_;
            walk_print($item->{$_}, $path, $depth);
            pop @$path;
        }
    } else {
	print join('->', map { "{$_}"} @$path, $item), "\n" if defined($item);
    }
}

sub purge {
    my ($directory, $blocks, $keys)=@_;
    my ($iblock, $ikey);
    foreach $iblock ( @{ $blocks } ){
	foreach $ikey ( @{ $keys } ){
	    if(key_exist($directory,$iblock,$ikey)){
		delete($directory->{$iblock}->{$ikey});
	    }
	}
    }
}

sub counter {
    my ($n) = @_;
    return sub {
	return ++$n;
    };
}

sub find_defined {
    my( $ref, $path, $fkey, %userparam ) = @_ ;
    my @loop;
    my $ipath;
    my %OPTIONS;

    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$OPTIONS{$key}=$value;
    }

    $fkey='*' unless defined $fkey;

    my @a=split /\*/, $path;
    my $path0=shift @a;
    my @path0=parse_path($path0);
    my $ref0=key_defined( $ref, @path0);

    if( ref $ref0 eq 'HASH' ) {
	@loop=keys(%{$ref0});
    }
    elsif( ref $ref0 eq 'ARRAY' ) {
	@loop=(0..$#{$ref0});
    }
    else{
	return ();
    }

    my @pathlist=();
    my @newpathlist=();
    foreach (@loop){
	push @pathlist, [@path0,$_];
    }

    for(my $i=0;$i<@a;$i++){
	my @pathN=parse_path($a[$i]);      # get new segment form path string
	foreach $ipath (@pathlist){        # loop over found paths
	    my @pathfind=(@{$ipath},@pathN);
	    my $refN=key_defined( $ref, @pathfind);

	    if($refN){
		push @newpathlist, [@pathfind];
	    }
	}
	@pathlist=@newpathlist;
    }

    my @outstring=();
    my @outarray=();
    foreach $ipath (@pathlist){
	my $value=$ipath->[$#{$ipath}];
	if($fkey eq '*' || $fkey eq $value){
	    push @outstring, join('/',@{$ipath});
	    push @outarray, [@{$ipath}];
	}
    }

    if(exists($OPTIONS{strings}) && $OPTIONS{strings} eq 'true'){
	return @outstring;
    }
    else{
	return @outarray;
    }
}

1;
