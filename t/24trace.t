#!perl
use Test::More tests => 1;
use strict;
use File::Spec;

BEGIN {
    $ENV{DATA_POSTPONED_TRACE} = 1;
}
use Data::Postponed 'postpone_forever';

my ( $volume, $directory, undef ) = File::Spec->splitpath( $0 );
my $outfile = File::Spec->catpath( $volume, $directory, "debug.tst" );
local *OUT;
open OUT, "> $outfile\0"
  or die "Couldn't open $outfile for writing: $!";

{
    local *STDERR = *OUT;
    my $o = postpone_forever( 1 );
    $o = $o . 2;
    
    # Get this to finalize and thus get the wrapped finalizers to
    # be called.
    my $x = "" . substr( $o, 0 );
}

close OUT
  or die "Couldn't close/flush $outfile: $!";

my $size = -s $outfile;
cmp_ok( $size, ">", 0,
	"Tracing wrote data" );
