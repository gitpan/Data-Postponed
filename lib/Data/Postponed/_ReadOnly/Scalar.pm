package Data::Postponed::_ReadOnly::Scalar;
use strict;
use Carp 'croak';

sub TIESCALAR {
    my $val = $_[1];
    bless \ $val, $_[0];
}
sub FETCH { ${shift()} }
sub STORE { croak( "Modification of a read-only value attempted" ) }
sub DESTROY {} # Nothing special.

1;

__END__

=head1 NAME

Data::Postponed::_ReadOnly::Scalar - Cause a scalar to be readonly

=head1 SYNOPSIS

 tie $foo, 'Data::Postponed::_ReadOnly::Scalar',
   $default;

=head1 DESCRIPTION

This tie() module is used by L<Data::Postponed::OnceOnly> to force
input variables to be readonly.

=head1 METHODS

Data::Postponed::_ReadOnly::Scalar implments the entire scalar tie
object.

=over 4

=item ->TIESCALAR( $default_value )

This ties the scalar and stores the default value into the scalar.

=item FETCH

This returns the value stored into the scalar when it was tied.

=item STORE

This returns a fatal error. Storing new values is not allowed.

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



