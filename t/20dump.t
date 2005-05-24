#!perl
use Test::More tests => 1;
use strict;
use File::Spec;

BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone_forever';

my ( $volume, $directory, undef ) = File::Spec->splitpath( $0 );
my $outfile = File::Spec->catpath( $volume, $directory, "debug.tst" );
local *OUT;
open OUT, "> $outfile\0"
  or die "Couldn't open $outfile for writing: $!";

my $stdout = select *OUT;
postpone_forever( undef )->Dump;
select $stdout;

close OUT
  or die "Couldn't close/flush $outfile: $!";

my $size = -s $outfile;
cmp_ok( $size, ">", 0,
	"->Dump wrote data" );
