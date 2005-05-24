#!perl
use strict;
use Test::More tests => 20;
use File::Spec;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone_forever';
use constant PERLVER => $];

{
    local $_ = postpone_forever "a";
    $_ = $_ . $_;
    is( $_,
        "aa",
        "Intermediate values" );
}

{
    local $_ = postpone_forever "a";
    $_ .= $_;
    is( $_,
        "aa",
        "Intermediate values" );
}

{
    local $_ = postpone_forever "a";
    my $b = \ "b";
    $_ .= $b;
    is( $_,
        "a$b",
        "Refs ok" );
}

{
    local $_ = postpone_forever "a";
    my $b = T->new;
    $_ .= $b;
    is( $_,
        "a$b",
        "Overloads ok" );
}

{
    my $in = \ "a";
    local $_ = postpone_forever $in;
    is( $_,
        $in,
        "Reference" );
}

cmp_ok( chr ord postpone_forever( "a" ),
        'eq',
        'a',
        'Finalize ""' );

cmp_ok( ord chr postpone_forever( 1 ),
        '==',
        1,
        'Finalize 0+' );

ok( ( postpone_forever( "" )
      ? 0
      : 1 ),
    'Finalize bool' );
SKIP: {
    skip "Dereference operators aren't overloadable in 5.5.x", 10
      if PERLVER < 5.006;
    
    {
	$main::test = "foobar";
	is( ${postpone_forever( "test" )},
	    "foobar",
	    "Finalize soft \${}" );
    }
    
    is( ${postpone_forever( \ "foobar" )},
	"foobar",
	"Finalize hard \${}" );
    
    {
	@main::test = ( 1 );
	ok( eq_array( [@{ postpone_forever( "test" ) }],
		      [ 1 ] ),
	    "Finalize soft \@{}" );
    }

    ok( eq_array( [@{ postpone_forever( [ 1 ] ) }],
		  [ 1 ] ),
	"Finalize hard \@{}" );
    
    {
	%main::test = ( foo => 'bar' );
	ok( eq_hash( {%{ postpone_forever( "test" ) }},
		     { foo => 'bar' } ),
	    "Finalize soft %{}" );
    }
    
    ok( eq_hash( {%{ postpone_forever( { foo => 'bar' } ) }},
		 { foo => 'bar' } ),
	"Finalize hard %{}" );
    
    is( &{postpone_forever( "one" )},
	2,
	"Finalize soft &{}" );
    sub one { 2 }
    
    is( &{postpone_forever( sub { 1 } )},
	1,
	"Finalize hard &{}" );
    
    is( \*{postpone_forever( 'STDOUT' )},
	\*main::STDOUT,
	"Finalize soft *{}" );
    
    is( *{postpone_forever( \*main::STDOUT )},
	*main::STDOUT,
	"Finalize hard *{}" );
}

SKIP: {
    skip "Iterator operator isn't overloadable in 5.5.x", 2
      if PERLVER < 5.006;
    
    my ( $volume, $directory, undef ) = File::Spec->splitpath( $0 );
    my $filename = File::Spec->catpath( $volume, $directory, "debug.tst" );
    
    open OUT, "> $filename\0"
      or die "Couldn't open $filename for writing: $!";
    print OUT "Some text\n"
      or die "Couldn't write to $filename: $!";
    close OUT
      or die "Couldn't close $filename: $!";
    
    open IN, "< $filename\0"
      or die "Couldn't open $filename: $!";
    is( readline( postpone_forever( "IN" ) ),
	"Some text\n",
	"Finalize soft <>" );
    close IN
      or die "Couldn't close $filename after reading: $!";
    
    open IN, "< $filename\0"
      or die "Couldn't open $filename: $!";
    is( readline( postpone_forever( \*IN ) ),
	"Some text\n",
	"Finalize hard <>" );
    close IN
      or die "Couldn't close $filename after reading: $!";
}

package T;
use overload( '""' => sub { "String" } );
sub new { bless [], "T" }
