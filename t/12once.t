use strict;
use Test::More tests => 4;
use Data::Postponed 'postpone_once';

{
  my $val = 1;
  my $expr = postpone_once $val;

  is( $expr, 1, 'once 1' );
  
  $val++;
  is( $expr, 2, 'once 2' );

  substr $expr, 1, 1, 'b';
  is( $expr, '2b', 'once 3' );

  $val = "unused val";
  is( $expr, '2b', 'once 4' );
}
