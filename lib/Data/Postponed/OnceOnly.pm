package Data::Postponed::OnceOnly;
use strict;
use vars ( '@ISA' );
use Data::Postponed::Util::NoLonger;
use Data::Postponed::Util::ReadOnly::Scalar;

BEGIN {
    @ISA = 'Data::Postponed';
    *TRACE = *Data::Postponed::TRACE;
    *DEBUG = *Data::Postponed::DEBUG;
    *isa = \ &UNIVERSAL::isa;
}

sub _Finalize {
    TRACE and
      warn "Data::Postponed::Once::_Finalize for " . overload::StrVal($_[0]) . "\n";
    my $str = overload::StrVal( $_[0] );
    my $data = $Data::Postponed::Objects{$str};
    my $val = \ &{ $_[0]->can( 'SUPER::_Finalize' ) }( @_ );
    
    # Mark the contents of this as object as read-only.
    for ( grep ref(), @$data ) {
	eval {
	    tie $$_, "Data::Postponed::Util::ReadOnly::Scalar" =>
	      $$_;
	};
	my $e = "$@";
	if ( $e
	     and not $e =~ /Modification of a read-only value attempted/ ) {
	    die $e;
	}
    }
    
    @$data = $val;
    
    # Do my DESTROY work because now DESTROY is going to go somewhere
    # else and this data will be orphaned otherwise. If memory gets
    # re-used, then the same underlying data might even be visible to
    # another object. Yuck.
    delete $Data::Postponed::Values{$str};
    delete $Data::Postponed::Objects{$str};
    
    Data::Postponed::Util::NoLonger->steal( $_[0], $$val );
    
    # return $_[0] = $$val;
    return $$val;
}

1;

__END__

=head1 NAME

Data::Postponed::OnceOnly - Put off computing a value as long as possible but throw errors if later changes are attempted

=head1 SYNOPSIS

Example using C<postpone()>

 use Data::Postponed 'postpone';
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo'. $code isn't
 # overloaded anymore.
 print $code;
 
 # This line is now an error because $functions{foobar} is readonly.
 $functions{foobar} = "quux";
 
 # This line isn't reached.
 print $code;

Example using the OO

 use Data::Postponed;
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . Data::Postpone::OnceOnly->new( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # This line is now an error because $functions{foobar} is readonly.
 $functions{foobar} = "quux";
 
 # This line isn't reached.
 print $code;

=head1 DESCRIPTION

The value of expressions that have had postpone called on them are in
flux until finalized. Once finalized, they are no longer overloaded
and any input variables used to compute the expression are changed to
be readonly.

This will cause your program to throw errors if you attempt to modify
something that has already been used to finalize something. That's the
point. If you don't want that, use L<Data::Postponed::Once>
instead. It is identical except that it won't mark your variables as
read only.

=head1 METHODS

=over 4

=item Data::Postponed::OnceOnly->new( EXPR )

Returns a new overloaded object bound to whatever was passed in as the EXPR.

=back

=head2 Overridden methods

=over 4

=item C<"">, C<0+>, C<bool>

Each of these methods are overridden from L<Data::Postponed>. If you
wished to only finalize strings, you might just copy the C<""> and
C<new> methods to your own subclass of L<Data::Postponed>.

=back

=head1 SEE ALSO

L<Data::Postponed>, L<Data::Postponed::Once>, L<Data::Postponed::Forever>, L<overload>

This is inspired by what I originally thought
L<Quantum::Superpositions> did. Here, the idea is that a value's
actual value is in flux until it is examined hard enough and then is a
real value.

This module is used in L<B::Deobfuscate> to turn a two pass algorithm
into a single pass. I would have had to do a complete run to get a
final symbol table and then run it again to actually use the symbol
table. This module allows me to change my mind about the values I've
returned.

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

