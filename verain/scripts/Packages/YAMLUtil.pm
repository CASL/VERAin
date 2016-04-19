package YAMLUtil;

# fix from
# http://www.perlmonks.org/index.pl/www.slashcode.org?node_id=813726

use Exporter;
@ISA = ('Exporter');
@EXPORT=('mergekeys_loop',
	 'mergekeys_recursive'
    );

sub mergekeys_loop          # Quick fix for perl YAML. Remove after
			    # someone fixes it.
{
    my ($orig) = @_;
    while (my $ref = shift)
    {
        my $type = ref $ref;
        if ($type eq 'HASH')
        {
            my $tmphref = $ref->{'<<'};
            if ($tmphref)
            {
                die "Merge key does not support merging non-hashmaps"
                    unless (ref $tmphref eq 'HASH');
                my %tmphash = %$tmphref;
                delete $ref->{'<<'};
                %$ref = (%tmphash, %$ref);
            }
            push @_, grep {ref eq 'HASH' or ref eq 'ARRAY'} values %$ref;
        }
        elsif ($type eq 'ARRAY')
        {
            push @_, grep {ref eq 'HASH' or ref eq 'ARRAY'} @$ref;
        }
    }
    return $orig;
}

sub mergekeys_recursive
{
    my ($ref) = @_;
    my $type = ref $ref;
    if ($type eq 'HASH')
    {
        my $tmphref = $ref->{'<<'};
        if ($tmphref)
        {
            die "Merge key does not support merging non-hashmaps"
                unless (ref $tmphref eq 'HASH');
            my %tmphash = %$tmphref;
            delete $ref->{'<<'};
            %$ref = (%tmphash, %$ref);
        }
        mergekeys_recursive($_) for (values %$ref);
    }
    elsif ($type eq 'ARRAY')
    {
        mergekeys_recursive($_) for (@$ref);
    }
    return $ref;
}

1;
