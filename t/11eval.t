use strict;
use Test::More tests => 51;
use Data::Postponed (
  'postpone', 'postpone_once', 'postpone_forever' );

# Exports ok
ok( defined &postpone, 'postpone() was exported' );
ok( defined &postpone_forever, 'postpone_forever() was exported' );
ok( defined &postpone_once, 'postpone_once() was exported' );

# OO returns an overloaded object
# ->new returns the proper object
isa_ok( Data::Postponed::OnceOnly->new( undef ), 'Data::Postponed::OnceOnly' );
isa_ok( Data::Postponed::OnceOnly->new( undef ), 'Data::Postponed' );
isa_ok( Data::Postponed::Once->new( undef ), 'Data::Postponed::Once' );
isa_ok( Data::Postponed::Once->new( undef ), 'Data::Postponed' );
isa_ok( Data::Postponed::Forever->new( undef ), 'Data::Postponed::Forever' );
isa_ok( Data::Postponed::Forever->new( undef ), 'Data::Postponed' );

# Functional returns an overloaded object
isa_ok( postpone( undef ), 'Data::Postponed::OnceOnly' );
isa_ok( postpone( undef ), 'Data::Postponed' );
isa_ok( postpone_once( undef ), 'Data::Postponed::Once' );
isa_ok( postpone_once( undef ), 'Data::Postponed' );
isa_ok( postpone_forever( undef ), 'Data::Postponed::Forever' );
isa_ok( postpone_forever( undef ), 'Data::Postponed' );

ok( overload::Overloaded( postpone( undef ) ),
    'postpone() overloads' );
ok( overload::Overloaded( postpone_forever( undef ) ),
    'postpone_forever() overloads' );
ok( overload::Overloaded( postpone_once( undef ) ),
    'postpone_once() overloads' );
ok( ! eval{ Data::Postponed->new( undef ); 1 },
    'Data::Postponed->new is a virtual method' );

#{ # Stealable
#  my $val = postpone_forever *postpone_forever{CODE};
#  print STDERR $val->[0] . "\n";
#  exit;
#  like( $val, qr/^\d+$/, );
#}

{ # Mixed objects
  my $val1 = 100;
  my $val2 = "one hundred";
  my $expr1 = postpone_forever $val1;
  my $expr2 = postpone_forever $val2;

  is( $expr1 . $expr2 . $expr1 . $expr2,
      '100one hundred100one hundred' );
}

{ # Addition
  my $val1 = 100;
  my $val2 = 100;
  my $expr = postpone_forever( $val1 );
  
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

  $expr = $expr - $expr;
  $expr -= $val2;

  is( $expr, $val1 - $val1 - $val2, '- 1' );

  $val1++;
  is( $expr, $val1 - $val1 - $val2, '- 2' );

  $val2--;
  is( $expr, $val1 - $val1 - $val2, '- 3' );
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
