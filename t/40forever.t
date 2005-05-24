#!perl
use Test::More tests => 37;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone_forever';
# $SIG{__WARN__} = sub {
#     local $_ = shift;
#     my $caller = 1;
#     $caller++ while caller $caller;
#     my $prefix = sprintf "%d %s", $caller, '   ' x $caller;
#     s/^/$prefix|/mg;
#     print STDERR;
# };

{ # Mixed@ objects
  my $val1 = 100;
  my $val2 = "one hundred";
  my $expr1 = postpone_forever $val1;
  my $expr2 = postpone_forever $val2;

  is( $expr1 . $expr2 . $expr1 . $expr2,
      '100one hundred100one hundred',
      'Mixed objects' );
}

{ # References are stored ok.
  my $val_a = "this";
  my $val_b = "that";
  my $val = \ $val_a;

  my $expr = postpone_forever $val;
  $val = \ $val_b;
  is( $expr, \ $val_b,
      'References can be changed too.' );
}

{ # Postponed objects can also be substituted.
  my $val = postpone_forever "this";
  my $expr = postpone_forever $val;
  $val = "that";

  is( $expr, "that", "Postponed objects can be substited as well" );
}

{ # Recursive objects are handled ok
  my $expr = postpone_forever "a";
  $expr = $expr . $expr;

  is( $expr, "aa", "Recursive objects are handled ok" );
}

{ # Numification
  my $val = "1 this";
  my $expr = postpone_forever $val;

  $val = "2 that";
  is( 0 + $expr, 2, "Objects can be numified" );
}

{ # Booleanification
  my $val = "";
  my $expr = postpone_forever $val;
  $val = 1;

  ok( $expr, "Objects can be booleanified" );
}

{ # Addition
  my $val1 = 100;
  my $val2 = 100;
  my $expr = postpone_forever $val1;
  
  $expr = $expr + $val2 + $val1;
  $expr += $val2;

  is( $expr, $val1 + $val2 + $val1 + $val2, '+ 1' );

  $val1++;
  is( $expr, $val1 + $val2 + $val1 + $val2, '+ 2' );

  $val2--;
  is( $expr, $val1 + $val2 + $val1 + $val2, '+ 3' );
}

{ # Subtraction
    my $val1 = 100;
    my $val2 = 100;
    my $expr = postpone_forever( $val1 );
    
    $expr -= $expr; # 100 - 100
    $expr -= $val2; # -= 100
    $expr = $expr - $val2; # -= 100

    cmp_ok( $expr, "==", 100 - 100 - 100 - 100, '- 1' );

    $val1++;
    cmp_ok( $expr, "==", 101 - 101 - 100 - 100, '- 2' );

    $val2--;
    cmp_ok( $expr, "==", 101 - 101 - 99 - 99, "- 3" );
}

{ # Multiplication
  my $val1 = 100;
  my $val2 = 100;
  my $expr = postpone_forever( $val1 );

  $expr = $expr * $val2 * $val1;
  $expr *= $val2;

  is( $expr, $val1 * $val2 * $val1 * $val2, '* 1' );

  $val1++;
  is( $expr, $val1 * $val2 * $val1 * $val2, '* 2' );

  $val2--;
  is( $expr, $val1 * $val2 * $val1 * $val2, '* 3' );
}

{ # Division
  my $val1 = 100;
  my $val2 = 100;
  my $val3 = 100;
  my $expr = postpone_forever( $val1 );

  $expr = $expr / $val2 / $val1;
  $expr /= $val3;

  is( $expr, $val1 / $val2 / $val1 / $val3, '/ 1' );

  $val1++;
  is( $expr, $val1 / $val2 / $val1 / $val3, '/ 2' );

  $val2--;
  is( $expr, $val1 / $val2 / $val1 / $val3, '/ 3' );

  $val3++;
  is( $expr, $val1 / $val2 / $val1 / $val3, '/ 3' );
}

{ # Modulus
  my $val1 = 100;
  my $val2 = 100;
  my $expr = postpone_forever( $val1 );

  $expr = $expr % $expr;
  $expr %= $val2;

  is( $expr, $val1 % $val1 % $val2, '% 1' );

  $val1++;
  is( $expr, $val1 % $val1 % $val2, '% 2' );

  $val2--;
  is( $expr, $val1 % $val1 % $val2, '% 3' );
}

{ # Exponentiation
  my $val1 = 2;
  my $val2 = 2;
  my $expr = postpone_forever( $val1 ) ** $val2;

  $expr **= $val1;

  is( $expr, ( ( $val1 ** $val2 ) ** $val1 ), '** 1' );

  $val2--;
  is( $expr, ( ( $val1 ** $val2 ) ** $val1 ), '** 2' );

  $val1--;
  is( $expr, ( ( $val1 ** $val2 ) ** $val1 ), '** 3' );
}

{ # Left bitshift
  my $val1 = 2;
  my $val2 = 3;
  my $expr = postpone_forever( $val1 );

  $expr <<= $val2;

  is( $expr, $val1 << $val2, '<< 1' );

  $val1++;
  is( $expr, $val1 << $val2, '<< 2' );

  $val2--;
  is( $expr, $val1 << $val2, '<< 3' );
}

{ # Right bitshift
  my $val1 = 2;
  my $val2 = 3;
  my $expr = postpone_forever( $val1 );

  $expr >>= $val2;

  is( $expr, $val1 >> $val2, '>> 1' );

  $val1++;
  is( $expr, $val1 >> $val2, '>> 2' );

  $val2--;
  is( $expr, $val1 >> $val2, '>> 3' );
}

{ # x
  my $val1 = 2;
  my $val2 = 3;
  my $expr = postpone_forever( $val1 );

  $expr x= $val2;

  is( $expr, $val1 x $val2, 'x 1' );

  $val1++;
  is( $expr, $val1 x $val2, 'x 2' );

  $val2--;
  is( $expr, $val1 x $val2, 'x 3' );
}

{ # concatenation
  my $val1 = 2;
  my $val2 = 3;
  my $expr = postpone_forever( $val1 );

  $expr .= $val2;

  is( $expr, $val1 . $val2, '. 1' );

  $val1++;
  is( $expr, $val1 . $val2, '. 2' );

  $val2--;
  is( $expr, $val1 . $val2, '. 3' );
}
