#!perl -T
use Test::More;
use overload ();
if ( eval { require Test::Pod::Coverage;
            Test::Pod::Coverage->import();
            1 } ) {
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
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage: $@";
}

