#!perl
use Test::More tests => 10;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
#    $ENV{DATA_POSTPONED_TRACE} = 1;
}
use Data::Postponed 'postpone_once';

{
    my $input = 10;
    my $expr = postpone_once $input;
    cmp_ok( $expr, '==', 10, "Simple eval ok" );
}

is( scalar( keys %Data::Postponed::Objects ),
    0 );
is( scalar( keys %Data::Postponed::Values ),
    0 );

{
    my $input = 11;
    my $expr = postpone_once $input;
    $input++;
    
    # Postponed value follows reference
    cmp_ok( $expr, '==', 12, "Postpone ok" );
}

is( scalar( keys %Data::Postponed::Objects ),
    0 );
is( scalar( keys %Data::Postponed::Values ),
    0 );

{
    my $input = 13;
    my $expr = postpone_once $input;

    # Finalize $expr
    $expr = ord chr $expr;
    $input++;
    
    # Postponing stops following after finalization
    cmp_ok( $expr, "==", 13, "Postponing stopped ok, direct" );
}

is( scalar( keys %Data::Postponed::Objects ),
    0 );
is( scalar( keys %Data::Postponed::Values ),
    0 );

{
    my $input = 14;
    my $expr = postpone_once $input;

    # Finalize $expr
    $expr = ord chr "$expr\n";
    $input++;

    # Postponing stops following after finalization
    cmp_ok( $expr, "==", 14, "Postponing stopped ok, indirect" );
}
