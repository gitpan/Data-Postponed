#!perl
use Test::More tests => 5;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed;

ok( Data::Postponed->can( 'import' ),
    "Data::Postponed can import()" );

# Test for function exports
for my $function ( 'postpone',
		   'postpone_once',
		   'postpone_forever' ) {
    ok( eval { Data::Postponed->import( $function ); 1 },
	"Data::Postponed exports $function" );
}

cmp_ok( Data::Postponed->VERSION, '>=', 0.01,
	"Data::Postponed->VERSION is specified" );
