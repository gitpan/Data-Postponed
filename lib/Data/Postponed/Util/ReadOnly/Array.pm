package Data::Postponed::_ReadOnly::Array;
use strict;
use Carp 'croak';

sub TIEARRAY { bless [ @_[ 1 .. $#_ ] ], $_[0] }
sub FETCH { $_[0][$_[1]] }
sub FETCHSIZE { 0 + @{$_[0]} }
sub DESTROY {} # Nothing special.

if ( $] >= 5.006 ) {
    eval q[ sub EXISTS { exists $_[0][$_[1]] }; 1 ];
}

for my $method ( qw( STORE STORESIZE EXTEND DELETE CLEAR PUSH POP SHIFT UNSHIFT SPLICE ) ) {
    eval "sub $method { croak( 'Data::Postponed: Modification of a read-only value attempted' ) }; 1";
}

1;
