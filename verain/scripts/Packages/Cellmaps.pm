package Cellmaps;

use Data::Types qw(:all);
use List::MoreUtils::PP;

use MiscUtils;
use TypeUtils;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('full_size',
	 'oct_size',
	 'qtr_size',
	 'dia_size',
	 'gen_oct_list',
	 'gen_quad_list',
	 'gen_quad_list_rot',
	 'gen_dia_list',
	 'fullcellmap',
	 'fullcellmap_rot',
	 'extract_map',
	 'map_on_core',
	 'core_map'
    );

{
    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }

    my $_DEBUG = 0;
    sub get_debug  {$_DEBUG;}
    sub set_debug { $_DEBUG = 1; }
}

sub full_size ($) {
    my $size=shift;

    unless(is_int($size) && $size > 0){
	die "full_size: size not valid: $size\n";
    }

    my $total=$size*$size;
    return $total;
}

sub oct_size ($) {
    my $size=shift;

    unless(is_int($size) && $size > 0){
	die "oct_size: size not valid: $size\n";
    }

    if(is_odd($size)){
	$size--;
	$size=$size/2+1;
    }
    else{
	$size=$size/2;
    }

    my $total=0;
    $total += $_ foreach (1..$size);
    return $total;
}

sub qtr_size ($) {
    my $size=shift;

    unless(is_int($size) && $size > 0){
	die "qtr_size: size not valid: $size\n";
    }

    if(is_odd($size)){
	$size--;
	$size=$size/2+1;
    }
    else{
	$size=$size/2;
    }

    my $total=$size*$size;
    return $total;
}

sub dia_size ($) {
    my $size=shift;

    unless(is_int($size) && $size > 0){
	die "dia_size: size not valid: $size\n";
    }

    my $total=diagsum($size);
    return $total;
}

# generates array with full map from a list of octal symmetry
# mirror symmetry option
# Scott 12/16/2015: octal rotational symmetry is mirror symmetry
sub gen_oct_list {
    my ($isize,@cellmap)=@_;
    my ($i,$j);
    my @a=();
    my @b=();

    my $ITLIMIT=$isize+3;

    my $ibound=int($isize/2);
    my @bounds;
    if(is_odd($isize)){
	@bounds=(-$ibound..$ibound);
    }
    else{
	$ibound--;
	@bounds=(-$ibound..0); $bounds[-1]=-0.1;
	push @bounds, map { -$_ } reverse @bounds;
    }

    my $it = incrmf3($ITLIMIT, 1, 1);  # create iterator for partitioning
    my @part = part { $it->($_) } @cellmap; # get list of references to array chunks
    my $map8=index_map(\@part,'OCTANT'); # make addressing function mapping into the original array chunks

    foreach $i (@bounds){
	@a=();
	foreach $j (@bounds){
	    $i=int($i);
	    $j=int($j);
	    push @a, $map8->($i,$j);
	    push @b, $map8->($i,$j);
	}
    }
    print "gen_oct_list: @a\n\t\tfrom $isize: @cellmap" if get_verbose();

    return @b;
}

# generates array with full map from a list of quarter symmetry
# mirror symmetry option
sub gen_quad_list {
    my ($isize,@cellmap)=@_;
    my ($i,$j);
    my @b=();

    my $ITLIMIT=$isize+3;

    my $ibound=int($isize/2);
    my @bounds;
    if(is_odd($isize)){
	@bounds=(-$ibound..$ibound);
    }
    else{
	$ibound--;
	@bounds=(-$ibound..0); $bounds[-1]=-0.1;
	push @bounds, map { -$_ } reverse @bounds;
    }

    my $it = incrmf3($ITLIMIT, 1, 1, $ibound);
    my @part = part { $it->($_) } @cellmap;
    my $map4=index_map(\@part,'QUARTER');

    foreach $i (@bounds){
	my @a=();
	foreach $j (@bounds){
	    $i=int($i);
	    $j=int($j);
	    push @a, $map4->($i,$j);
	    push @b, $map4->($i,$j);
	}
    }
    print "gen_quad_list: @a\n\t\tfrom $isize: @cellmap" if get_verbose();
    return @b;
}

# generates array with full map from a list of quarter symmetry
sub gen_quad_list_rot {
    my ($isize,@cellmap)=@_;
    my ($i,$j);
    my @b=();

    my $ITLIMIT=$isize+3;

    my $ibound=int($isize/2);
    my @bounds;
    if(is_odd($isize)){
	@bounds=(-$ibound..$ibound);
    }
    else{
	$ibound--;
	@bounds=(-$ibound..0); $bounds[-1]=-0.1;
	push @bounds, map { -$_ } reverse @bounds;
    }

    my $it = incrmf3($ITLIMIT, 1, 1, $ibound);
    my @part = part { $it->($_) } @cellmap;

    unless(&is_quartermap_rot(\@part)){
	print "gen_quad_list_rot: quarter map @cellmap is not rotational\n"  if get_verbose();
    }
    
    my $map4=index_map_rotational(\@part,'QUARTER');
    foreach $i (@bounds){
	my @a=();
	foreach $j (@bounds){
	    push @a, $map4->($i,$j);
	    push @b, $map4->($i,$j);
	}
    }
    print "gen_quad_list_rot: @a\n\t\tfrom $isize: @cellmap" if get_verbose();
    return @b;
}

sub gen_dia_list {
    my ($isize,@cellmap)=@_;
    my ($i,$j);
    my @a=();
    my @b=();

    my $ITLIMIT=$isize+3;

    my $ibound=int($isize/2);
    my @bounds;
    if(is_odd($isize)){
	@bounds=(-$ibound..$ibound);
    }
    else{
	$ibound--;
	@bounds=(-$ibound..0); $bounds[-1]=-0.1;
	push @bounds, map { -$_ } reverse @bounds;
    }

    my $it = incrmf3($ITLIMIT, 1, 1);       # create iterator for partitioning
    my @part = part { $it->($_) } @cellmap; # get list of references to array chunks

#    for($i=0; $i<$isize; $i++){
    for($i=0; $i<@bounds; $i++){
	@a=();
#	for($j=0; $j<$isize; $j++){
	for($j=0; $j<@bounds; $j++){
	    if($j<=$i){
		push @a, $part[$i]->[$j];
	    }
	    else{
		push @a, $part[$j]->[$i];
	    }
	}
	push @b, @a;
    }
    print "gen_dia_list: @b\n\t\tfrom $isize: @cellmap" if get_verbose();

    return @b;
}


# incrmf3(20,1,1) will create iterator to partion array in pyramidal chunks
# incrmf3(20,1,8) iterator for square chunks of size 8
sub incrmf3 {
    my ($nmax,$counter_inc,$bin_inc,$bin_size)=@_;
    my $m=0;
    my $n=0;
    return sub {
	if($m<= ($bin_size ? $bin_size : $n)){
	    $m=$m+$counter_inc;
	}
	else{
	    $m=1;
	    $n=$n+$bin_inc;
	}
	return $n > $nmax ? undef : $n;
    };
}

sub index_map {
    my ($map,$type)=@_;
    my $m=@{ $map };

    if(uc($type) eq 'OCTANT'){
	return sub {
	    my ($i,$j)=@_;

	    $i=abs($i);
	    $j=abs($j);
	    if($j>$i){
		my $t=$i;
		$i=$j;
		$j=$t;
	    }

	    unless(defined($map->[$i]->[$j])){
		die "index_map: undefined OCTANT $i $j\n";
	    }

	    my $value= $map->[$i]->[$j];

	    return $value;
	}
    }
    if(uc($type) eq 'QUARTER'){
	return sub {
	    my ($i,$j)=@_;

	    $i=abs($i);
	    $j=abs($j);

	    unless(defined($map->[$i]->[$j])){
		die "index_map: undefined QARTER $i $j\n";
	    }

	    my $value= $map->[$i]->[$j];

	    return $value;
	}
    }
    undef;
}

sub fullcellmap {
    my ($npin,$aref)=@_;
    my @b=();

    my @a=@{ $aref };
    my $qtrsize =qtr_size($npin);
    my $octsize =oct_size($npin);
    my $fullsize=full_size($npin);
    my $diasize =dia_size($npin);

    if(@a == $qtrsize){
	@b=gen_quad_list($npin,@a);
    }
    elsif(@a == $octsize){
	@b=gen_oct_list($npin,@a);
    }
    elsif(@a == $diasize){
	@b=gen_dia_list($npin,@a);
	print "fullcellmap: diagonal map $npin: @a not tested yet.\n"  if get_verbose();
    }
    elsif(@a == $fullsize){
	@b=@a;
    }
    else{
	die "fullcellmap: invalid map size ($#a) for map dimension ($npin): $qtrsize, $octsize, $diasize, \n";
    }

    return @b;
}

sub fullcellmap_rot {
    my ($npin,$aref)=@_;
    my @b=();

    my @a=@{ $aref };
    my $qtrsize =qtr_size($npin);
    my $octsize =oct_size($npin);
    my $fullsize=full_size($npin);

    if(@a == $qtrsize){
	@b=gen_quad_list_rot($npin,@a);
    }
    elsif(@a == $octsize){
	# Scott 12/16/2015: octal rotational symmetry is mirror symmetry
	@b=gen_oct_list($npin,@a);
    }
    elsif(@a == $fullsize){
	@b=@a;
    }
    else{
	die "fullcellmap_rot: invalid map $npin [@a]\n";
    }
    return @b;
}

sub extract_map{
    my($ary,$n,$m,$maptype)=@_;
    my $na=@{ $ary };

    die "extract_map: indices not valid $n, $m, $na\n"
	if ($n <= 0 || 
	    $m <= 0 || 
	    ($n*$m > $na)
	);

    my $nhalf=int($n/2);
    my $mhalf=int($m/2);
    my $icenter= $nhalf * $m + $mhalf;  # central location

    $icenter += ($n%2) ? 0 : 1;

    my @result = ();
    if($maptype eq 'OCTANT'){
	for(my $i=0; $i<=$nhalf;$i++){
	    for(my $j=0; $j<=$i;$j++){
		push @result, $ary->[$icenter+$i*$m+$j];
	    }
	}
	return wantarray ? @result : \@result;
    }
    if($maptype eq 'QUARTER'){
	for(my $i=0; $i<=$nhalf;$i++){
	    for(my $j=0; $j<=$mhalf;$j++){
		push @result, $ary->[$icenter+$i*$m+$j];
	    }
	}
	return wantarray ? @result : \@result;
    }
    
    die "extract_map: invalid maptype: $maptype\n";

}

sub map_on_core{
    # writes map $ary2 onto core map $ary
    # map $ary is derived from original map by
    # filling it in by core map
    my($ary,$n,$m,$ary2,$maptype)=@_;
    my $na=@{ $ary };
    my @ary2  = @{ $ary2 };
    my $t;

    die "map_on_core: indices not valid $n, $m, $na\n"
	if ($n <= 0 || 
	    $m <= 0 || 
	    ($n*$m > $na)
	);

    die "map_on_core: array to apply is empty\n"
	unless(@ary2);

    my $nhalf=int($n/2);
    my $mhalf=int($m/2);
    my $icenter= $nhalf * $m + $mhalf;  # central location

    $icenter += ($n%2) ? 0 : 1;

    if($maptype eq 'OCTANT'){
	for(my $i=0; $i<=$nhalf;$i++){
	    for(my $j=0; $j<=$i;$j++){
		$t = shift @ary2;
		unless(defined($t)){
		    die "map_on_core: missing entry in OCTANT map to apply\n";
		}
		$ary->[$icenter+$i*$m+$j]=$t;
	    }
	}
	return 1;
    }
    if($maptype eq 'QUARTER'){
	for(my $i=0; $i<=$nhalf;$i++){
	    for(my $j=0; $j<=$mhalf;$j++){
		$t = shift @ary2;
		unless(defined($t)){
		    die "map_on_core: missing entry in OCTANT map to apply\n";
		}
		$ary->[$icenter+$i*$m+$j]=$t;
	    }
	}
	return 1;
    }
    
    die "map_on_core: invalid maptype: $maptype\n";

}

sub core_map{
    my ($cmap, $mmap, $n, $bc_sym, %userparam)=@_;
    my %OPTIONS;
	
    while ( my ($key, $value) = each %userparam ) # to avoid perl bug of $$
    {$OPTIONS{$key}=$value;}

    # how many 1 in core shape
    my $nfull=times_in_array($cmap,1);

    my @core = @{ $cmap };
    replace_in_array(\@core,1,'_USED_');
    replace_in_array(\@core,0,'_EMPTY_');
    
    # get octant and quarter maps from core shape
    my @core_map_o=extract_map(\@core,$n,$n,'OCTANT');
    my $noct      =times_in_array(\@core_map_o,'_USED_');
    my @core_map_q=extract_map(\@core,$n,$n,'QUARTER');
    my $nquad     =times_in_array(\@core_map_q,'_USED_');

    # elements in the other map
    my $nmmap=@{ $mmap };

    my @ccmap;
    my @resmap;
    my @fullm = @core; # full map in the shape of core
    my @fullmp;        # purged map from empty entries in core

    print STDERR "core_map: $bc_sym\n"  if get_verbose();;

    my $IGNORE='-';
    if(exists($OPTIONS{ignore})){
	$IGNORE=$OPTIONS{ignore};
    }
    
  MAPS: { 
      if($nmmap == $noct){
	  @ccmap=@core_map_o;
	  @resmap=fillin(\@ccmap, $mmap, '_USED_');

	  if(exists($OPTIONS{expand}) && $OPTIONS{expand} == 0){
	      replace_in_array(\@fullm,'_USED_',$IGNORE);
	      map_on_core(\@fullm,$n,$n,\@resmap,'OCTANT');
	      last MAPS;
	  }

	  if($bc_sym eq 'mir'){
	      @fullm=fullcellmap($n,\@resmap);
	  }
	  else{
	      # Scott 12/16/2015: octal rotational symmetry is mirror symmetry
	      @fullm=fullcellmap($n,\@resmap);
	  }
      }
      elsif ($nmmap == $nquad){
	  @ccmap=@core_map_q;
	  @resmap=fillin(\@ccmap, $mmap, '_USED_');

	  if(exists($OPTIONS{expand}) && $OPTIONS{expand} == 0){
	      replace_in_array(\@fullm,'_USED_',$IGNORE);
	      map_on_core(\@fullm,$n,$n,\@resmap,'QUARTER');
	      last MAPS;
	  }

	  if($bc_sym eq 'mir'){
	      @fullm=fullcellmap($n,\@resmap);
	  }
	  else{
	      @fullm=fullcellmap_rot($n,\@resmap);
	  }
      }
      elsif ($nmmap == $nfull){
	  @fullm=@{ $mmap };
      }
      else{
	  die "core_map: invalid map, map=$nmmap, octant=$noct, quarter=$nquad, full=$nfull\n";
      }
    }

    @fullmp=purge_array(\@fullm,'_EMPTY_');
    return  wantarray ? @fullmp : \@fullmp;
}

sub index_map_rotational {
    my ($map,$type)=@_;
    my $m=@{ $map };

    # odd  size core indices -n ..     0    .. +n
    # even size core indices -n .. -0.1,0.1 .. +n
    # this index is only used for quarter maps
    # Scott 12/16/2015: octal rotational symmetry is mirror symmetry
    #    therefore, no need to have octal maps here

    if(uc($type) eq 'QUARTER'){
	return sub {
	    my ($ibar,$jbar)=@_;
	    my ($i,$j)=($ibar,$jbar);

	    # default, SE region=1
	    # ibar>=0, jbar>=0
	    my $region=1;
	    

	    # second quadrant, NE = 2
	    ($ibar < 0 && $jbar >  0) &&
		do{
		    $i=         $jbar;
		    $j=-$ibar;
		    $region=2;
	    };
	    # third quadrant, NW = 3
	    ($ibar <  0 && $jbar <  0) &&
		do{
		    $i=-$ibar;
		    $j=-$jbar;
		    $region=3;
	    };
	    # fourth quadrant
	    ($ibar >  0 && $jbar <   0) &&
		do{
		    $i=        -$jbar;
		    $j= $ibar;
		    $region=4;
	    };

	    # for odd size core fill out N
	    if($jbar == 0 && $ibar < 0){
		$i = $jbar;
		$j = -$ibar;
	    }
	    # for odd size core fill out W
	    if($ibar == 0 && $jbar < 0){
		$i = -$jbar;
		$j = $ibar;
	    }
	    
	    unless(defined($map->[$i]->[$j])){
		die "quad: $region ($ibar, $jbar) = ($i,$j)\n";
	    }

	    my $value= $map->[$i]->[$j];

	    return $value;
	}
    }
    else{
	die "index_map_rotational: invalid type $type\n";
    }
    undef;
}

sub is_quartermap_rot ($) {
    $r=shift;

    my @a=@{ $r->[0] };
    for(my $i=0; $i<@a; $i++){
	if($a[$i] != $r->[$i]->[0]){
	    return 0;
	}
    }
    return 1;
}
    
1;
