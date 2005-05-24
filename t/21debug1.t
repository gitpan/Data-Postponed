#!perl
use Test::More tests => 1;
use strict;

BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed;

SKIP: {
    skip "Debugging is disabled without Carp::Assert", 1
      if not scalar keys %Carp::Assert::;

    ok( do { package Data::Postponed;
	     DEBUG },
	'DATA_POSTPONE_DEBUG=1 -> Data::Postponed::DEBUG = t' );
}
