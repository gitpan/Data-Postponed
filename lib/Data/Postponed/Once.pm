package Data::Postponed::Once;
use strict;
use vars ( '@ISA' );

@ISA = 'Data::Postponed';

sub new {
    bless [ Data::Postponed::_ByValueOrReference( $_[1] ) ],
      $_[0];
}

sub DESTROY {} # Don't bother AUTOLOADing this

for my $context ( split ' ', $overload::ops{conversion} ) {
    no strict 'refs';
    my $super = "SUPER::$context";
    *{__PACKAGE__ . "::$context"} = sub {
	my ( $self ) = @_;
	my $value = $self->$super();
	
	@$self = $value;
	return $_[0] = $value;
    };
}

1;

__END__

=head1 NAME

Data::Postponed::Once - Delayed evaluation expressions are "collapsed" once observed

=head1 SYNOPSIS

Example using C<postpone_once()>

 use Data::Postpone 'postpone_once';
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone_once( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo'. $code isn't
 # overloaded anymore.
 print $code;
 
 # The change to $functions{foobar} is no longer reflected in $code
 $functions{foobar} = "quux";
 print $code;

Example using the OO

 use Data::Postpone;
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . Data::Postpone::Once->new( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # The change to $functions{foobar} is no longer reflected in $code
 $functions{foobar} = "quux";
 print $code;

=head1 DESCRIPTION

The value of expressions that have had postpone called on them are in
flux until finalized. Once finalized, they are no longer overloaded.

If you want to also prevent changes to input variables because you
don't want to accidentally think you're reaching back in time when
you're not, use L<DatA::Postpone::OnceOnly>.

=head1 METHODS

=over 4

=item Data::Postponed::Once->new( EXPR )

Returns a new overloaded object bound to whatever was passed in as the EXPR.

=back

=head2

=over 4

=item C<"">, C<0+>, C<bool>

Each of these methods are overridden from L<Data::Postpone>. If you
wished to only finalize strings, you might just copy the C<""> and
C<new> methods to your own subclass of L<Data::Postpone>.

=back

=head1 SEE ALSO

L<Data::Postponed>, L<Data::Postponed::OnceOnly>,
L<Data::Postponed::Forever>, L<overload>

This is inspired by what I originally thought
L<Quantum::Superpositions> did. Here, the idea is that a value's
actual value is in flux until it is examined hard enough and then is a
real value.

The companion module L<Data::Postponed::OnceOnly> is used in
L<B::Deobfuscate> to turn a two pass algorithm into a single pass. I
would have had to do a complete run to get a final symbol table and
then run it again to actually use the symbol table. This module allows
me to change my mind about the values I've returned.

=head1 AUTHOR

Joshua ben Jore, C<< <jjore@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-postponed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Postponed>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

L<Corion> of perlmonks.org

=head1 COPYRIGHT & LICENSE

Copyright 2005 Joshua ben Jore, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
