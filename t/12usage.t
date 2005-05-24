#!perl
use Test::More tests => 7 * 3;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed ( 'postpone_forever',
                      'postpone_once',
                      'postpone' );

SKIP: {
    skip "Test::Exception is required for these tests", 7*3
      if ! eval "use Test::Exception; 1;";
    
    for my $func( 'postpone_forever',
		  'postpone_once',
		  'postpone' ) {
	eval qq[ dies_ok( sub { $func() },
                      "$func() dies" ) ];
	eval qq[ lives_ok( sub { $func( 1 ) },
                       "$func( EXPR ) lives" ) ];
	eval qq[ dies_ok( sub { $func( 1, 2 ), },
                      "$func( EXPR, EXPR ... ) dies"  ) ];
	
	my $stdout = select;
	eval qq[ lives_ok( sub { my \$old = select NOWHERE;
                             $func( 1 )->Dump;
                             select \$old },
                       "$func( EXPR )->Dump lives" ) ];
	
	select $stdout;
	eval qq[ dies_ok( sub { $func( 1 )->Dump( 1 ) },
                      "$func( EXPR )->Dump( EXPR, ... ) dies" ) ];
	
	eval qq[ lives_ok( sub { $func( 1 )->_Data },
                       "$func( EXPR )->_Data lives" ) ];
	eval qq[ dies_ok( sub { $func( 1 )->_Data( 1 ) },
                      "$func( EXPR )->_Data( ... ) dies" ) ];
    }
}



