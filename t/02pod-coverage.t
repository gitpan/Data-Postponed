#!perl -T
use Test::More;
use overload ();
eval "use Test::Pod::Coverage;";
if ( not $@ ) {
    my $overload
      = '^(?:SVs_PADTMP|SVs_TEMP|DESTROY|'
	. join( '|',
		map quotemeta(),
		map split( ' ' ),
		values %overload::ops )
	  . ')$';
    all_pod_coverage_ok({ trustme => [ qr($overload) ] });
}
else {
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
}

