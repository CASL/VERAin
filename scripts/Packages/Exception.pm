package Exception;

use Carp;

use Exporter;
@ISA = ('Exporter');
@EXPORT=('try',
	 'throw',
	 'catch',

	 'exception',
	 'exception_subr',
	 'exception_error',
	 'exception_log',

	 'push_trace_file',
	 'flush_trace_file',
	 'trace_file',

	 'push_trace_command',
	 'flush_trace_command',
	 'trace_command'
    );

{
    my $_EXCEPTION;
    my %_TRACE;

    my $_VERBOSE = 0;
    sub get_verbose  {$_VERBOSE;}
    sub set_verbose { $_VERBOSE = 1; }

    my $_DEBUG = 0;
    sub get_debug  {$_DEBUG;}
    sub set_debug { $_DEBUG = 1; }
}


    
# exception structure after throw
sub exception {
    my %arg = @_;
    my @t;
    unless(exists($arg{subr})){
	print STDERR "<<WARNING>> Exception handler: missing subr info\n";
	@t=&trace_file();
	print STDERR "            Trace file: @t\n";
	@t=&trace_command();
	print STDERR "            Trace command: @t\n";
    }
    unless(exists($arg{error})){
	print STDERR "<<WARNING>> Exception handler: missing error info\n";
	@t=&trace_file();
	print STDERR "            Trace file: @t\n";
	@t=&trace_command();
	print STDERR "            Trace command: @t\n";
   }
    $_EXCEPTION=Exception->new(@_);
}
sub exception_subr {
    return $_EXCEPTION->subr();
}
sub exception_error {
    return $_EXCEPTION->error();
}
sub exception_log {
    print "Exception created\n" if get_verbose();
    return $_EXCEPTION->log();
}

# managing trace
sub push_trace_file ($) {
    push @{ $_TRACE{file} }, @_;
}
sub flush_trace_file {
    @{ $_TRACE{file} }=();
}
sub trace_file {
    return @{ $_TRACE{file} };
}

sub push_trace_command ($) {
    push @{ $_TRACE{command} }, @_;
}
sub flush_trace_command {
    @{ $_TRACE{command} }=();
}
sub trace_command {
    return @{ $_TRACE{command} };
}

# Base exception mechanism
sub try(&)   { eval {$_[0]->()} }
sub throw($) { die $_[0] }
sub catch(&) { $_[0]->($@) if $@ }

sub new
{
    my ($class, %arg) = @_;

    my $self={
	subr  => exists($arg{subr})  ? $arg{subr}   : undef,
	error => exists($arg{error}) ? $arg{error}  : undef,
	log   => exists($arg{log})   ? $arg{log}    : undef,
    };
    bless $self, $class;
}

sub subr
{
    if(defined($_EXCEPTION->{subr})){
	return sprintf "Subroutine: %s\n", $_EXCEPTION->{subr};
    }
}

sub error
{
    if(defined($_EXCEPTION->{error})){
	return sprintf "Error: %s\n", $_EXCEPTION->{error};
    }
}

sub log
{
    if(defined($_EXCEPTION->{log})){
	return sprintf "Log: %s\n", $_EXCEPTION->{log};
    }
}

1;
