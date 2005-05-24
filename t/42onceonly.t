#!perl
use Test::More tests => 6;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone';
my $TEST_EXCEPTION = eval 'use Test::Exception; 1';

{
    my $input = 10;
    my $expr = postpone $input;
    
    cmp_ok( $expr, '==', 10, "Simple eval ok" );
}

{
    my $input = 10;
    my $expr = postpone $input;
    $input++;
    
    # Postponed value follows reference
    cmp_ok( $expr, '==', 11, "Postpone ok" );
}

{
    my $input = 10;
    my $expr = postpone $input;

    # Finalize $expr
    $expr = ord chr $expr;
    
    # Postponing stops following after finalization
  SKIP: {
	skip "Test::Exception needed to test this", 1
	  if not $TEST_EXCEPTION;
	throws_ok( sub { $input++ }, qr/Modification of a read-only value attempted/, "Modification stopped, direct" );
    }
    cmp_ok( $expr, "==", 10, "Postponing stopped ok, direct" );
}

{
    my $input = 10;
    my $expr = postpone $input;
    
    # Finalize $expr
    $expr = ord chr "$expr\n";
    
    # Postponing stops following after finalization
  SKIP: {
	skip "Test::Exception needed to test this", 1
	  if not $TEST_EXCEPTION;
	
	throws_ok( sub { $input++ }, qr/Modification of a read-only value attempted/, "Modification stopped, indirect" );
    }
    cmp_ok( $expr, "==", 10, "Postponing stopped ok, indirect" );
}
