#!perl -T
use Test::More;
use overload ();
if ( ! eval "use Test::Pod::Coverage; 1" ) {
  plan skip_all => "Test::Pod::Coverage required for testing POD coverage: $@";
}

my $overload
  = '^(?:SVs_PADTMP|SVs_TEMP|'
  . join( '|',
	  map quotemeta(),
	  map split( ' ' ),
	  values %overload::ops )
  . ')$';
all_pod_coverage_ok({ trustme => [ qr($overload) ] });
