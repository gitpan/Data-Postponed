package Data::Postponed::Util::ReadOnly::Scalar;
use strict;
use Carp 'croak';

sub TIESCALAR { bless do { my $val = $_[1]; \ $val }, $_[0] }
sub FETCH { ${$_[0]} }
sub STORE { croak( "Data::Postponed: Modification of a read-only value attempted" ) }
sub DESTROY {} # Nothing special.

1;
