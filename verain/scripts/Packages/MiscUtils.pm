package MiscUtils;

use List::MoreUtils::PP;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('nonzero',
	 'unique',
	 'fany',
	 'fall',
	 'fnone',
	 'fnotall',
	 'ftrue',
	 'ffalse',
	 'odd',
	 'even',
	 'fronthalf',
	 'endhalf',
	 'min',
	 'max',
	 'compare_arrays',
	 'union',
	 'intersection',
	 'difference',
	 'nonstring',
	 'arraysize',
	 'first',
	 'last',
	 'nth',
	 'mmult',
	 'transpose',
	 'everynth',
	 'skipeverynth',
	 'stride',
	 'factorial',
	 'diagsum',
	 'txt2xml',
	 'is_increasing',
	 'is_strictlyincreasing',
	 'is_decreasing',
	 'is_strictlydecreasing',
	 'times_in_array',
	 'fillin',
	 'purge_array',
	 'replace_in_array',
	 'extract_options',
	 'append_options'
    );

{
    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }
}

sub nonzero { # remove zeros from array entry
    @_ = grep { $_ != 0 } @_;
    return @_;
}

sub nonstring { # remove strings from array entry
    my $str=shift;
    @_ = grep { $_ ne $str } @_;
    return @_;
}

sub unique (@) { # return unique entries from an array
    my %saw = ();
    grep { not $saw{$_}++ } @_;
}

# One argument is true, f* uses function for evaluation
sub fany (&@) { my $f=shift; $f->($_) && return 1 for @_; 0 }

# All arguments are true
sub fall (&@) { my $f=shift; $f->($_) || return 0 for @_; 1 }

# All arguments are false
sub fnone (&@) { my $f=shift; $f->($_) && return 0 for @_; 1 }

# One argument is false
sub fnotall (&@) { my $f=shift; $f->($_) || return 1 for @_; 0 }

# How many elements are true
sub ftrue (&@) { my $f=shift; scalar grep { $f->($_) } @_ }

# How many elements are false
sub ffalse (&@) { my $f=shift; scalar grep { !$f->($_) } @_ }

# get elements with odd indices, 1,3,5,7,
sub odd {my $aref=shift; return map {$aref->[$_]} grep {$_ & 1} 1..$#{$aref};}

# get elements with even indices, 0,2,4,6
sub even {my $aref=shift; return map {$aref->[$_]} grep {($_+1) & 1} 0..$#{$aref};}

# get front half of an array 
sub fronthalf {my ($aref,$offset)=@_; return @{$aref}[$offset..int(($#{$aref}+$offset)/2)];}

# get end half of an array 
sub endhalf {my ($aref,$offset)=@_; return @{$aref}[int(($#{$aref}+$offset)/2)+1..$#{$aref}];}

sub min{ # minimum value
    (sort { $a <=> $b } @_)[0];
}

sub max{ # maximum value
    (sort { $b <=> $a } @_)[0];
}

sub compare_arrays {
    my ($first, $second) = @_;
    no warnings;  # silence spurious -w undef complaints
    return 0 unless @$first == @$second;
    for (my $i = 0; $i < @$first; $i++) {
	return 0 if $first->[$i] ne $second->[$i];
    }
    return 1;
} 

# must add prototypes
sub aryop { # various operations on arrays
    my ($first,$second,$OPERATOR)=@_;

    my @array1=@{ $first };
    my @array2=@{ $second };
    my @union=();
    my @intersection=();
    my @difference=();
    my %count = ();
    my $element;

    foreach $element (@array1, @array2) { $count{$element}++ }
    foreach $element (keys %count) {
	push @union, $element;
	push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
    }
    if(lc($OPERATOR) eq 'union'){
	return @union;
    }
    elsif(lc($OPERATOR) eq 'intersection'){
	return @intersection;
    }
    elsif(lc($OPERATOR) eq 'difference'){
	return @difference;
    }
    else{
	return undef;
    }
}

sub union {
    my ($first, $second) = @_;
    return aryop($first,$second,'union');
}
sub intersection {
    my ($first, $second) = @_;
    return aryop($first,$second,'intersection');
}
sub difference {
    my ($first, $second) = @_;
    return aryop($first,$second,'difference');
}

sub arraysize {
    my $size=@_;
    return $size;
}

sub first {
    return $_[0];
}
sub last {
    return $_[-1];
}
sub nth ($@) {
    my ($idx,@a)=@_;
    return $a[$idx] || undef;
}

sub everynth ($@) {
    my ($n,@a)=@_;
    my $i;

    my @b=grep {not ++$i % $n} @a;
    return @b;
}

sub stride ($$@) {
    my ($offset,$n,@a)=@_;
    my $i;

    my @c=splice @a, $offset;
    my $b=shift @c;
    my @b=grep {not ++$i % $n} @c;

    return ($b,@b);
}

sub skipeverynth ($@) {
    my ($n,@a)=@_;
    my $i;

    my @b=grep {++$i % $n} @a;
    return @b;
}

# multiply two matrices which are arrays of arrays
sub mmult {
    my ($rows, $cols, $m1, $m2) = @_;
    my $m3 = [];
    --$rows; --$cols;
    for my $i (0 .. $rows) {
        for my $j (0 .. $cols) {
            $m3->[$i][$j] += $m1->[$i][$_] * $m2->[$_][$j] for 0..$cols;
        }
    }
    return $m3;
}

# transpose a matrix
sub transpose {
    my $matrix = shift;
    my @result;
    my $m;

    for my $col (@{$matrix->[0]}) {
        push @result, [];
    }
    for my $row (@{$matrix}) {
        $m=0;
        for my $col (@{$row}) {
            push(@{$result[$m++]}, $col);
        }
    }

    return \@result;
}


sub factorial ($) {
    my $num = shift;
    my $fac = 1;

    unless($num >= 0){
	die "factorial: number not valid: $num\n";
    }

    $fac *= $num-- while $num > 0;
    return $fac;
}

sub diagsum ($) {
    my $num = shift;
    my $fac = 0;

    unless($num > 0){
	die "diag: number not valid: $num\n";
    }

    $fac += $num-- while $num > 0;
    return $fac;
}

sub txt2xml {
    my $r = shift;

    if (ref($r) eq "SCALAR") {
	$$r =~ s/&/&amp;/g;
	$$r =~ s/</&lt;/g;
#	$$r =~ s/>/&gt;/g;
#       should this trigger error, like unbalanced quotes?
	$$r =~ s/'/&apos;/g;
	$$r =~ s/"/&quot;/g;
	return 1;
    }
    elsif (ref($r) eq "ARRAY") {
	for (my $i = 0; $i <= $#$r; $i++) {
	    $r->[$i];
	    $r->[$i] =~ s/&/&amp;/g;
	    $r->[$i] =~ s/</&lt;/g;
#	    $r->[$i] =~ s/>/&gt;/g;
	    $r->[$i] =~ s/'/&apos;/g;
	    $r->[$i] =~ s/"/&quot;/g;
	}
	return 1;
    }
    else{
	die "txt2xml: incorrect data reference type\n";
    }
}

sub is_increasing (@) {    # assumes number validation for the array in previous rule
    my @a=@_;
    my @s=sort { $a <=> $b } @a;

    for(my $i=0;$i<@a;$i++){
	return 0 if $a[$i] != $s[$i];
    }
    return 1;
}

sub is_strictlyincreasing (@) {    # assumes number validation for the array in previous rule
    my @a=@_;
    my @s=sort { $a <=> $b } @a;

    @s=&unique(@s);
    return 0 if @a != @s;
    
    for(my $i=0;$i<@a;$i++){
	return 0 if $a[$i] != $s[$i];
    }
    return 1;
}

sub is_decreasing (@) {    # assumes number validation for the array in previous rule
    my @a=@_;
    my @s=sort { $a <=> $b } @a;

    for(my $i=0;$i<@a;$i++){
	return 0 if $a[$i] != $s[$i];
    }
    return 1;
}

sub is_strictlydecreasing (@) {    # assumes number validation for the array in previous rule
    my @a=@_;
    my @s=sort { $b <=> $a } @a;

    @s=&unique(@s);
    return 0 if @a != @s;
    
    for(my $i=0;$i<@a;$i++){
	return 0 if $a[$i] != $s[$i];
    }
    return 1;
}

sub times_in_array{
    my ($ary,$symbol)=@_;

    my $n=0;
    foreach (@{ $ary }){
	$n++ if $_ eq $symbol;
    }
    return $n;
}

sub fillin{
    my ($ary1, $ary2, $valid)=@_;
    my @result;
    my $i;

    @result= map { $_ eq $valid ? $ary2->[$i++] : '_EMPTY_' } @{ $ary1 };

    return  wantarray ? @result : \@result;
}

sub purge_array{
    my ($ary, $invalid)=@_;
    my @result;
    my $i;

    @result= grep { $_ ne $invalid } @{ $ary };

    return  wantarray ? @result : \@result;
}

sub replace_in_array ($$$) {
    my ($ary,$from,$to)=@_;

    my $n=0;
    foreach (@{ $ary }){
	$n++ if s/$from/$to/g;
    }
    return $n;
}

sub extract_options{
    my $contref = shift @_;

    my @content=@{ $contref };
    my @slshs=indexes { $_ eq '/' } @content;
    if(@slshs > 1){
	die "extract_options: invalid number of slashes in @content\n";
    }

    my @part2=();
    if(@slshs == 1){
	my @part1=before {$_ eq '/'} @content;
	@part2=after  {$_ eq '/'} @content;
	@{ $contref }= @part1;
    }

    return @part2;
}

sub append_options{
    my ($contref,@opts)=@_;

    if(@opts){
	push @{ $contref }, '/';
	push @{ $contref }, @opts;
	return 1;
    }
    return 0;
}

1;
