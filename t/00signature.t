use Test::More;
BEGIN {
    eval {
        require Test::Signature;
        Test::Signature->import();
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
