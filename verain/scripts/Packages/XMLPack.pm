package XMLPack;

use Carp;

use KeyTree;
use PL;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('packXMLlist',
	 'packXMLparameter',
	 'packXMLarray',
    );

{
    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }

    my $_DEBUG = 0;
    sub get_debug  {$_DEBUG;}
    sub set_debug { $_DEBUG = 1; }
}

sub packXMLparameter {
    my ($ref,$name,$phandle,$Nindent,%userparam)=@_;

    my %OPTIONS=('indent'=>'  ');
    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$OPTIONS{$key}=$value;
    }

    my $data=read_off_label($ref,'_content');
    my $type=read_off_label($ref,'_type');

    if(defined($data)){
	my $indent=$OPTIONS{indent} x $Nindent;
	print $phandle "$indent<Parameter name=\"$name\" type=\"$type\" value=\"$data\"/>\n";
    }
}

sub packXMLarray {
    my ($ref,$name,$phandle,$Nindent,%userparam)=@_;
    local $" = ',';

    my %OPTIONS=('indent'=>'  ');
    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$OPTIONS{$key}=$value;
    }

    my $data=read_off_label($ref,'_content');
    my $type=read_off_label($ref,'_type');
    if($data){
	my @data=@{ $data };
	my $indent=$OPTIONS{indent} x $Nindent;
	print $phandle "$indent<Parameter name=\"$name\" type=\"Array($type)\" value=\"{@data}\"/>\n";
    }
}

sub packXMLlist {
    my ($ref,$name,$phandle,$Nindent,%userparam)=@_;

    my %OPTIONS=('indent'=>'  ');
    while ( my ($key, $value) = each %userparam )        # to avoid perl bug of $$
    {
	$OPTIONS{$key}=$value;
    }

    my $nameupd=PLname($ref);
    if(defined($nameupd)){
	$name=$nameupd;
    }

    my %a=PLkeys($ref);
    my @b=keys %a;
    return unless(@b > 0);
    print STDERR "Level $Nindent: found @b\n" if get_verbose();

    my $indent=$OPTIONS{indent} x $Nindent;

    print $phandle "$indent<ParameterList name=\"$name\">\n";
 
    $Nindent++;

    foreach my $PLentry (sort keys %a){
	if( PLtype($a{$PLentry} ) eq 'parameter'){
	    &packXMLparameter($a{$PLentry},$PLentry,$phandle,$Nindent);
	}
	if( PLtype($a{$PLentry} ) eq 'array'){
	    &packXMLarray($a{$PLentry},$PLentry,$phandle,$Nindent);
	}
	if( PLtype($a{$PLentry}) eq 'list'){
	    &packXMLlist($a{$PLentry},$PLentry,$phandle,$Nindent)     
	}
    }
    unless(exists($OPTIONS{notclose})){
	print $phandle "$indent</ParameterList>\n";
    }
}

1;
