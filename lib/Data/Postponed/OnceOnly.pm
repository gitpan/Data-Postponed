package Data::Postponed::OnceOnly;
use strict;
use vars ( '@ISA' );


@ISA = 'Data::Postponed';

sub new {
    bless [ Data::Postponed::_ByValueOrReference( $_[1] ) ],
      $_[0];
}

sub DESTROY {} # Don't bother AUTOLOADing this

# Attempt to use the 5.8.x Internals::SetReadOnly function and fail
# over to a tie()'d function if that isn't available.
#*SetReadOnly =
#  defined &Internals::SetReadOnly ? \ &Internals::SetReadOnly :
#  defined &Internals::SvREADONLY ? sub { Internals::SvREADONLY( $_[0], 1 ) } :
#  undef;


for my $context ( split ' ', $overload::ops{conversion} ) {
    no strict 'refs';
    my $super = "SUPER::$context";
    *{__PACKAGE__ . "::$context"} = sub {
	my ( $self ) = @_;
	
	# Make a copy of the contents of the value prior to allowing
	# the parent finalizer to run. They'll be gone otherwise.
#	if ( defined &SetReadOnly ) {
#	    SetReadOnly( \ $_ ) for @$self;
#	}
#	else {
	    eval { tie( $$_, 'Data::Postponed::_ReadOnly::Scalar',
			$$_ ) }
	      for @$self;
#	}
	my $value = $self->$super();
	
	# Now to be strict. All input variables are now marked read
	# only so they cannot be accidentally written to again. This
	# is actually going to mark a lot of extra stuff as read only
	# too but I don't really care because it was internal to
	# Data::Postponed and I'm about to let most of it expire in a
	# moment anyway.
	
	# I'm still going to the trouble of marking *everything*
	# because I want to be sure that I've covered my bases
	# regarding variables that have been passed in.
	print STDERR scalar ( @$self ) . "\n";
	
	# Now throw away all the history of symbolic calculation and
	# store only the final value. I think I may be wasting time by
	# doing this but since I'm not 100% sure, I'm doing this
	# anyway.
	@$self = ( $value );
	
	# Lastly, I make the implementation array read only and the
	# object holding the reference to the array.
#	if ( defined &SetReadOnly ) {
#	    SetReadOnly( \ @$self );
#	    SetReadOnly( $self );
#	}
#	else {
# 	    tie( @$self, 'Data::Postponed::_ReadOnly::Array' );
	    tie( $self, 'Data::Postponed::_ReadOnly::Scalar',
		 $self );
#	}
	
	return $_[0] = $value;
    };
}


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

package Data::Postponed::_ReadOnly::Array;
use strict;
use Carp 'croak';

sub TIEARRAY { bless [ @_[ 1 .. $#_ ] ], $_[0] }
sub FETCH { $_[0][$_[1]] }
sub FETCHSIZE { 0 + @{$_[0]} }
if ( $] >= 5.006 ) {
    eval q[ sub EXISTS { exists $_[0][$_[1]] }; 1 ];
}
sub DESTROY {} # Nothing special.

for my $method ( qw( STORE STORESIZE EXTEND DELETE CLEAR PUSH POP SHIFT UNSHIFT SPLICE ) ) {
    no strict 'refs';
    *$method = sub { croak( "Modification of a read-only value attempted" ) };
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

