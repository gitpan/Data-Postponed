#!perl
use Test::More tests => 4;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed;

for my $class ( 'Data::Postponed',
		'Data::Postponed::Forever',
		'Data::Postponed::Once',
		'Data::Postponed::OnceOnly',
	      ) {
    # Get *Data::Postponed::()
    ok( $class->can('()'),
        "Class $class is overloaded" );
}
