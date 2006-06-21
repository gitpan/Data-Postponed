package Data::Postponed::Once;
use strict;
use vars ('@ISA');
use Data::Postponed::Util::NoLonger;
use Scalar::Util 'refaddr';

BEGIN {
    @ISA     = 'Data::Postponed';
    *TRACE   = *Data::Postponed::TRACE;
    *DEBUG   = *Data::Postponed::DEBUG;
    *PERLVER = \&Data::Postponed::PERLVER;
    *assert  = \&Data::Postponed::assert;
    *isa     = \&UNIVERSAL::isa;
}

sub _Finalize {
    TRACE
        and warn "Data::Postponed::Once::_Finalize for "
        . refaddr( $_[0] ) . "\n";
    my $str = refaddr( $_[0] );
    if (DEBUG) {
        assert( exists $Data::Postponed::Objects{$str},
            "$str has a backend object" );
    }

    my $data   = $Data::Postponed::Objects{$str};
    my $method = $_[0]->can('SUPER::_Finalize');
    my $val    = \$_[0]->$method( @_[ 1 .. $#_ ] );
    @$data = $val;

    # Do my DESTROY work because now DESTROY is going to go somewhere
    # else and this data will be orphaned otherwise. If memory gets
    # re-used, then the same underlying data might even be visible to
    # another object. Yuck.
    if (DEBUG) {
        assert(
            !exists $Data::Postponed::Values{$str},
            "$str has no intermediate value pending"
        );
        assert(
            exists $Data::Postponed::Objects{$str},
            "$str still has a backend object"
        );
    }
    delete $Data::Postponed::Values{$str};
    delete $Data::Postponed::Objects{$str};

    Data::Postponed::Util::NoLonger->steal( $_[0], $$val );

    if ( PERLVER > 5.6 ) {

        # There's some bug in 5.6.x where overwriting this caused
        # values like '10' to appear to be '0'. I'm convinced its a
        # memory scribbling problem and I haven't seen it on anything
        # newer.
        $_[0] = $$val;
    }
    return $$val;
}

1;

__END__

=head1 NAME

Data::Postponed::Once - Delayed evaluation expressions are "collapsed" once observed

=head1 SYNOPSIS

Example using C<postpone_once()>

 use Data::Postponed 'postpone_once';
 
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

 use Data::Postponed;
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . Data::Postponed::Once->new( $functions{foobar} ) . " { return time }";
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
you're not, use L<Data::Postponed::OnceOnly>.

=head1 METHODS

=over 4

=item Data::Postponed::Once->new( EXPR )

Returns a new overloaded object bound to whatever was passed in as the EXPR.

=back

=head2

=over 4

=item C<"">, C<0+>, C<bool>

Each of these methods are overridden from L<Data::Postponed>. If you
wished to only finalize strings, you might just copy the C<""> and
C<new> methods to your own subclass of L<Data::Postponed>.

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
