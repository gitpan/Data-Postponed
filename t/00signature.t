use Test::More;
BEGIN {
    eval {
        use Test::Signature;
        plan( tests => 1 );
        $test = 1;
    }
    or do {
        plan( skip_all => "Test::Signature wasn't installed" );
    }
}
if ( $test ) {
    signature_ok();
}
