package Data::Postponed::_ReadOnly::Array;
use strict;
use Carp 'croak';

sub TIEARRAY { bless [ @_[ 1 .. $#_ ] ], $_[0] }
sub FETCH { $_[0][$_[1]] }
sub FETCHSIZE { 0 + @{$_[0]} }
sub EXISTS { exists $_[0][$_[1]] }
sub DESTROY {} # Nothing special.

for my $method ( qw( STORE STORESIZE EXTEND DELETE CLEAR PUSH POP SHIFT UNSHIFT SPLICE ) ) {
    no strict 'refs';
    *$method = sub { croak( "Modification of a read-only value attempted" ) };
}

1;

__END__

=head1 NAME

Data::Postponed::_ReadOnly::Array - A tie implementation of a read only array

=head1 SYNOPSIS

 tie @foo, 'Data::Postponed::_ReadOnly::Array',
   @defaults;

=head1 DESCRIPTION

This tie() module may be used by L<Data::Postponed::OnceOnly> to implement read only arrays.

=head1 METHODS

=over 4

=item TIEARRAY, FETCH, FETCHSIZE, EXISTS

These work as in normal arrays.

=item CLEAR, DELETE, EXTEND, POP, PUSH, SHIFT, UNSHIFT, SPLICE, STORE, STORESIZE

These methods all return fatal errors

=back

=head1 SEE ALSO

L<Data::Postponed::OnceOnly>

=head1 AUTHOR

Joshua ben Jore, C<< <jjore@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Joshua ben Jore, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
