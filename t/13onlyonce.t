use strict;
use Test::More tests => 4;
use Data::Postponed 'postpone';

{
  my $val = 1;
  my $expr = postpone $val;

  is( $expr, 1, 'Expression == proper value' );
  my $success = eval { $val = "Unexpected"; 1 };
  my $error = "$@";
  ok( ! $success, 'Write failed' );

  # $val == 0 if the write wasn't prevented.
  is( $val, 1, '$val == 1' );
  like( $error, qr/Modification of a read-only value attempted/, 'Proper error was thrown' );
}
