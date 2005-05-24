#!perl
use strict;
use Test::More;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone_forever';

sub assignable { shift =~ /^(?:\+|\-|\*\*?|\/|\%|\<\<|\>\>|x|\.)$/ }
sub is_unary { shift() =~ /^(?:\~|\!|abs|cos|exp|log|neg|sin|sqrt)$/ }

plan tests => ( (9 * grep { not is_unary( $_ ) } @Data::Postponed::POSTPONERS)
		+(8 * grep { is_unary( $_ ) } @Data::Postponed::POSTPONERS)
		+(9 * grep { not is_unary( $_ ) } @Data::Postponed::POSTPONERS )
		+(9 * grep { assignable( $_ ) } @Data::Postponed::POSTPONERS ) );

for my $operation ( @Data::Postponed::POSTPONERS ) {
    # 9 tests per binary operation
    # 8 tests per unary operation
    is_postponed( a2b( "postpone_forever( 1 )", $operation, "2" ),
                  a2b( 1, $operation, 2 ),
                  $operation,
                  !!0,
		  ( is_unary( $operation ) ? undef : 2 ),
		  "Normal" );
    if ( not is_unary( $operation ) ) {
	# 9 per operation
	is_postponed( a2b( 2, $operation, "postpone_forever( 1 )" ),
                      a2b( 2, $operation, 1 ),
		      $operation,
                      !!1,
		      2,
		      "Inverted" );
    }
    if ( assignable( $operation ) ) {
	# 9 tests per operation
	is_postponed( "do { my \$o = postpone_forever( 1 ); \$o $operation= 2 }",
                      "do { my \$o = 1; \$o $operation= 2 }",
		      $operation,
		      undef,
		      2,
		      "Assignment" );
    }
}

sub a2b {
    my ( $a, $op, $b ) = @_;
    return( $op eq 'neg' ? "- $a" :
            $op eq '!' ? "! $a" :
            $op eq '~' ? "~ $a" :
            $op eq 'atan2' ? "atan2( $a, $b )" :
            $op eq 'cos' ? "cos( $a )" :
            $op eq 'sin' ? "sin( $a )" :
            $op eq 'exp' ? "exp( $a )" :
            $op eq 'abs' ? "abs( $a )" :
            $op eq 'log' ? "log( $a )" :
            $op eq 'sqrt' ? "sqrt( $a )" :
            "$a $op $b" );
}

sub is_postponed {
    my $pcode = shift @_;
    my $ecode = shift @_;
    my ( $expected_operation,
         $inverted,
         $expected_value,
	 $name ) = @_;
    
    my $obj = eval $pcode;
    is( "$@", "", "Eval $pcode isn't an error" );
    my $non_obj = eval $ecode;

    is( Data::Postponed::_Finalize($obj), $non_obj,
        "$name: Computes expected value" );

    ok( ref( $obj ),
        "$name: '$expected_operation' returned a reference" );
    
    ok( ref( $obj ) && overload::Overloaded( $obj ),
        "$name: '$expected_operation' returned an overloaded value" );
    
    my $data = $obj->_Data;
    is( ( @$data % 2 ), 1,
        "$name: '$expected_operation' data must have N*2+1 entries" );
    
    cmp_ok( int( @$data / 2 ), '>=', 1,
            "$name: '$expected_operation' data has postponed operations" );

    if ( not $inverted ) {
	if ( not is_unary( $expected_operation ) ) {
	    cmp_ok( ${$data->[-1]}, "==", 2,
		    "$name: '$expected_operation' \$a data ok");
	}
	cmp_ok( ${$data->[-3]}, "==", 1,
		"$name: '$expected_operation' \$b data ok");
    }
    else {
        cmp_ok( ${$data->[-1]}, "==", 1,
                "$name: '$expected_operation' \$a data ok" );
	cmp_ok( ${$data->[-3]}, "==", 2,
		"$name: '$expected_operation' \$b data ok" );
    }
    is( $data->[-2], $expected_operation,
        "$name: '$expected_operation' operation data ok" );


    return;
}
