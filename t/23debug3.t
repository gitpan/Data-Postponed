#!perl
use Test::More tests => 1;
use strict;

BEGIN {
    delete $ENV{DATA_POSTPONED_DEBUG};
    $^D = 1;
}
use Data::Postponed;

SKIP: {
    skip "Debugging is disabled without Carp::Assert", 1
      if not scalar keys %Carp::Assert::;
    
    ok( do { package Data::Postponed;
	     DEBUG },
	'$^D -> Data::Postponed::DEBUG = t' );
}
