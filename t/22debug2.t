#!perl
use Test::More tests => 1;
use strict;

BEGIN {
    delete $ENV{DATA_POSTPONED_DEBUG};
}
use Data::Postponed;

ok( do { package Data::Postponed;
	 ! DEBUG },
    'DATA_POSTPONE_DEBUG= -> Data::Postponed::DEBUG = nil' );
