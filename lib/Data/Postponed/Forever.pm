package Data::Postponed::Forever;
use strict;
use vars ( '@ISA' );

@ISA = 'Data::Postponed';

sub new {
    bless [
	   Data::Postponed::_ByValueOrReference( $_[1] )
	  ],
	    $_[0];
}

sub DESTROY {} # Don't bother AUTOLOADing this

1;

__END__

=head1 NAME

Data::Postponed::Forever - Recompute values as needed to use post
facto changes to input variables

=head1 SYNOPSIS

Example using C<postpone_forever()>

 use Data::Postpone 'postpone_forever';
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone_forever( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # Continues to reflect changes to the input variables
 $functions{foobar} = "quux";
 print $code;

Example using the OO

 use Data::Postpone;
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . Data::Postpone::Forever->new( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # Continues to reflect changes to the input variables
 $functions{foobar} = "quux";
 print $code;

=head1 DESCRIPTION

The value of expressions that have had postpone_forever called on them
always reflect the current value of their input variables.

=head1 METHODS

=over 4

=item Data::Postponed::Forever->new( EXPR )

Returns a new overloaded object bound to whatever was passed in as the EXPR.

=back

=head2 Overridden methods

None. This is raw C<Data::Postponed>.

=head1 SEE ALSO

L<Data::Postponed>, L<Data::Postponed::OnceOnly>, L<Data::Postponed::Once>, L<overload>

This is pretty near identical to the "I<Really> symbolic calculator"
mentioned in L<overload>.

This is also really just Yet Another Templating Engine in
disguise. L<Corion> pointed this out to me. If you have a value which
always results in the value of C<"Hello $firstname, ... Regards,
$sender"> you could certainly just change the value of $firstname as
needed and thus generate template driven strings.

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
