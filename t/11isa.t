#!perl
use Test::More tests => 3;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed;

{
    my $o = Data::Postponed::Forever->new( undef );
    ok( Data::Postponed::Forever
	->new( undef )
	->isa( 'Data::Postponed' ),
	'::Forever ISA' );
}

{
    my $o = Data::Postponed::Once->new( undef );
    ok( Data::Postponed::Forever
	->new( undef )
	->isa( 'Data::Postponed' ),
	'::Once ISA' );
}

{
    my $o = Data::Postponed::Forever->new( undef );
    ok( Data::Postponed::Forever
	->new( undef )
	->isa( 'Data::Postponed' ),
	'::OnceOnly ISA' );
}
