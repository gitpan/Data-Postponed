package Data::Postponed;
use strict;
use vars qw( $VERSION $DEBUG @ISA @EXPORT_OK );
use overload (); # to be imported later
use B 'svref_2object';
use Carp 'croak';
use Exporter;
use Data::Postponed::Forever;
use Data::Postponed::Once;
use Data::Postponed::OnceOnly;

$VERSION = '0.03';

BEGIN {
    for my $flag ( [ SVf_READONLY => 0x00800000 ],
		   [ SVf_FAKE => 0x00100000 ],
		   [ SVs_TEMP => 0x00000800 ],
		   [ SVs_PADTMP => 0x00000200 ] ) {
	if ( grep $flag->[0] eq $_, @B::EXPORT_OK ) {
	    B->import( $flag->[0] );
	}
	else {
	    eval "sub $flag->[0] () { $flag->[1] }"
	}
	#	eval { B->import( $_->[0] ) }
#	  or eval "sub () $_->[0] { $_->[1] }"
#	    or die "Couldn't create $_->[0]: $@";
    }
}

######################################################################
#		 Function exports and OO composition
######################################################################

@ISA = 'Exporter';
@EXPORT_OK = ( 'postpone',
	       'postpone_once',
	       'postpone_forever' );

# sub import {
#     my ( $pkg ) = @_;
    
#     # This is undocumented and I'm not sure its useful for anything. I
#     # have this here so I can play with it.
    
#     # Everything that isn't specifically meant for me is given to Exporter.
#     my ( @exports, $constant );
#     for ( @_[ 1 .. $#_ ] ) {
#         if ( not defined $constant
# 	     and
# 	     /^:(postpone(?:_forever|_once)?)$/ ) {
# 	    $constant = do { no strict 'refs';
# 			     \ &$1 };
# 	    overload::constant( map { $_ => $constant }
# 				qw( integer float binary q qr ) );
#         }
# 	else {
# 	    push @exports, $_;
# 	}
#     }
    
#     if ( @exports ) {
# 	__PACKAGE__->export_to_level( 2, $pkg, @exports );
#     }
    
#     1;
# }

sub postpone_forever { return Data::Postponed::Forever->new( $_[0] ) }
sub postpone_once { return Data::Postponed::Once->new( $_[0] ) }
sub postpone { return Data::Postponed::OnceOnly->new( $_[0] ) }

sub new {
    croak( "Data::Postponed is a virtual class. You must call"
	   . " Data::Postponed::Forever->new,"
	   . " Data::Postponed::Once->new,"
	   . " or Data::Postponed::OnceOnly->new instead" );
}

######################################################################
#		     Oodles of overload.pm magic
######################################################################

overload->import
  (# Hook all the non-finalizing operations which will be stored
   # internally as "stuff to do" when a finalizing operation is
   # detected.
   
   # These are the pure-value changing methods. The original object
   # isn't modified so I just return a new object including the new
   # value and an operation.
   map( { ( $_ ) x 2 }
	map split( ' ' ),
	'=',
	@overload::ops{( 'with_assign',
			 'assign',
			 'num_comparison',
			 '3way_comparison',
			 'str_comparison',
			 'binary',
			 'unary',
			 'mutators',
			 'func',
			 'conversion',
			 'iterators',
			 # 'dereferencing',
			 # 'special'
		       )} ),
   
   '=' => "Clone" );

######################################################################
#			Postponing operations
######################################################################

# This is used for some deep introspection on the values being given
# to this module. I will attempt to only take references to variables
# and thus have a lighter in-memory load. This is handled by storing
# the literal value if it is noted as PADTMP or READONLY.

# If the value is SVf_READONLY, it is either a literal like "this is a
# literal" or it is a value someone marked as readonly. Normally the
# only values in perl that are flagged with SVf_READONLY are
# PL_sv_undef, PL_sv_yes, PL_sv_no, and PL_sv_placeholder

# If the value SVf_PADTMP has been set, the value is not derived from
# a variable lookup but is instead the result of some
# computation. like foo( time() ). Here, the value given to foo() is
# the result of computing time(). There is no way to later reference
# that value because if foo() doesn't store it, it will expire.

sub _ByValueOrReference {
    if ( ref $_[0] ) {
	if ( overload::Overloaded( $_[0] )
	     and $_[0]->isa( __PACKAGE__ ) ) {
	    # This value is an instance of this package. I'd rather
	    # clone it.
	    return \ bless [ @{$_[0]} ], ref $_[0];
	}
	else {
	    # A reference. Since I won't know later whether this is my
	    # reference or something that was passed in, I take a
	    # reference to it regardless. This makes postpone( \
	    # "literal" ) equivalent to postpone( \ $foo ).
	    
	    # As an aside, stuff blessed into the "0" and "\0" classes
	    # will fail this test. I don't care. People using those
	    # classes expect bad stuff.
	    return \ $_[0];
	}
    }
    elsif ( svref_2object( \ $_[0] )->FLAGS
	    & ( SVf_READONLY
		| SVf_FAKE
		| SVs_TEMP
		| SVs_PADTMP ) ) {
	# A literal value or a temporary value but definately not a
	# reference. So I store it by value. References might also be
	# stored by value but I don't know the difference between a
	# reference stored by value and a value stored by
	# reference. So references are always stored by reference and
	# values may or may not be.
	return $_[0];
    }
    else {
	# Everything else. This is actually identical to what happens
	# if I'm given a reference.
	
	# The caller is allowed (nay, *expected*) to change the
	# variable that I'm taking a referene to.
	return \ $_[0];
    }
}

# Non assignment, binary operations
for my $operation ( 'atan2',
		    map split( ' ' ),
		    @overload::ops{( 'with_assign',
				     'num_comparison',
				     '3way_comparison',
				     'str_comparison',
				     'binary' )} ) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$operation} = sub {
	bless [ @{$_[0]},
		_ByValueOrReference( $_[1] ),
		$_[2],
		$operation ],
		  ref $_[0];
    };
}

# Binary operations with assignment
for my $operation ( split ' ', $overload::ops{assign} ) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$operation} = sub {
	$_[0] = bless [ @{$_[0]},
			_ByValueOrReference( $_[1] ),
			$_[2],
			$operation ],
			  ref $_[0];
    };
}

# Unary operations with assignment
for my $operation ( split( ' ', $overload::ops{mutators} ) ) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$operation} = sub {
	$_[0] = bless [ @{$_[0]},
			undef,
			!!0,
			$operation ],
			  ref $_[0];
    };
}

# Non assignment unary operations
for my $operation ( qw( cos sin exp abs log int sqrt ),
		    map split( ' ' ),
		    @overload::ops{( 'unary',
				     'iterators' )} ) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$operation} = sub {
	bless [ @{$_[0]},
		undef,
		!!0,
		$operation ],
		  ref $_[0];
    };
}

######################################################################
#			  Cloning operation
######################################################################

sub Clone {
    # Clone the given object. This looks very much like _Postpone
    # except that it doesn't add anything new onto the evaluation
    # stack.
    my $self = shift;
    my $new = ref( $self )->new;
    @$new = @$self;
    
    return $new;
}

######################################################################
#			 Finalizing operation
######################################################################

for my $context ( split( ' ', $overload::ops{conversion} ) ) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$context} = sub {
	my $self = shift @_;
	
	# Iterate over all the values
	my $accumulator = do { local $_ = shift @$self;
			       ref() ? $$_ : $_ };
	
	while ( @$self ) {
	    my $a = $accumulator;
	    my ( $b, $inverted, $op ) = splice @$self, 0, 3;
	    
	    # If I stored a reference, dereference it now. This where
	    # stored references to things finally becomes
	    # finalized. I'm taking whatever the initial result was
	    # and making it my actual work product.
	    if ( ref $b ) {
		if ( overload::Overloaded( $b )
		     and
		     overload::StrVal( $b ) eq overload::StrVal( $self ) ) {
		    # This is an odd moment. If the thing I'm
		    # attempting to get the value if is the object I'm
		    # currently in, then I have a recursive structure.
		    
		    # I resolve this by noting that it wasn't
		    # recursive to begin with so the value for the
		    # recursive structure at this point must be
		    # whatever the $accumulator has in it.

		    # So the structure isn't *really* recursive, it is
		    # only implemented that way.
		    
		    # $expr = $expr + $expr will cause this
		    # situation. In a sense, $expr is now defined in
		    # terms of itself which means it is never
		    # defined. I say that if there is a definite
		    # execution order, ( $expr + $expr ) happens
		    # before the assignment so whatever the value in
		    # $accumulator is, that is what the $expr being
		    # added would be equal to.
		    $b = $accumulator;
		}
		else {
		    # This is where all the "magic" happens. Earlier
		    # in the program's execution, some ->"Postpone
		    # $op" method added this reference to the object
		    # instead of just taking whatever value was
		    # available at the moment.

		    # Now, I'm finally going to get the results from
		    # that object.
		    $b = $$b;
		}
	    }
	    
	    # If I need to swap $a and $b because of overload.pm, here
	    # is that moment.
	    if ( $inverted ) {
		( $a, $b ) = ( $b, $a );
	    }
	    
	    # Overwrite the accumulated value with the computation
	    # from the new expression.
	    $accumulator
	      = (# with_assign
		 # + - * / % ** << >> x .
		 '+' eq $op ? ( $a + $b ) :
		 '-' eq $op ? ( $a - $b ) :
		 '*' eq $op ? ( $a * $b ) :
		 '/' eq $op ? ( $a / $b ) :
		 '%' eq $op ? ( $a % $b ) :
		 '**' eq $op ? ( $a ** $b ) :
		 '<<' eq $op ? ( $a << $b ) :
		 '>>' eq $op ? ( $a >> $b ) :
		 'x' eq $op ? ( $a x $b ) :
		 '.' eq $op ? ( $a . $b ) :
		 
		 # assign
		 # += -= *= /= %/ **= <<= >>= x= .=
		 '+=' eq $op ? ( $a + $b ) :
		 '-=' eq $op ? ( $a - $b ) :
		 '*=' eq $op ? ( $a * $b ) :
		 '/=' eq $op ? ( $a / $b ) :
		 '%=' eq $op ? ( $a % $b ) :
		 '**=' eq $op ? ( $a ** $b ) :
		 '<<=' eq $op ? ( $a << $b ) :
		 '>>=' eq $op ? ( $a >> $b ) :
		 'x=' eq $op ? ( $a x $b ) :
		 '.=' eq $op ? ( $a . $b ) :
		 
		 # num_comparison
		 # < <= > >= == !=
		 '<' eq $op ? ( $a < $b ) :
		 '<=' eq $op ? ( $a <= $b ) :
		 '>' eq $op ? ( $a > $b ) :
		 '>=' eq $op ? ( $a >= $b ) :
		 '==' eq $op ? ( $a == $b ) :
		 '!=' eq $op ? ( $a != $b ) :
		 
		 # 3way_comparison
		 # <=> cmp
		 '<=>' eq $op ? ( $a <=> $b ) :
		 'cmp' eq $op ? ( $a cmp $b ) :
		 
		 # str_comparison
		 # lt le gt gt eq ne
		 'lt' eq $op ? ( $a lt $b ) :
		 'le' eq $op ? ( $a le $b ) :
		 'gt' eq $op ? ( $a gt $b ) :
		 'ge' eq $op ? ( $a ge $b ) :
		 'eq' eq $op ? ( $a eq $b ) :
		 'ne' eq $op ? ( $a ne $b ) :
		 
		 # binary
		 # & | ^
		 '&' eq $op ? ( $a & $b ) :
		 '|' eq $op ? ( $a | $b ) :
		 '^' eq $op ? ( $a ^ $b ) :
		 
		 # unary
		 # neg !
		 'neg' eq $op ? ( - $a ) :
		 '!' eq $op ? ( ! $a ) :
		 
		 # mutators
		 # ++ --
		 '++' eq $op ? ( ++ $a ) :
		 '--' eq $op ? ( -- $a ) :
		 
		 # func
		 # atan2 cos sin exp abs log sqrt
		 'atan2' eq $op ? atan2( $a, $b ) :
		 'cos' eq $op ? cos( $a ) :
		 'sin' eq $op ? sin( $a ) :
		 'exp' eq $op ? exp( $a ) :
		 'abs' eq $op ? abs( $a ) :
		 'log' eq $op ? log( $a ) :
		 'int' eq $op ? int( $a ) :
		 'sqrt' eq $op ? sqrt( $a ) :
		 
		 # conversion
		 # bool "" 0+
		 'bool' eq $op ? ( !! $a ) :
		 '""' eq $op ? "$a" :
		 '0+' eq $op ? ( 0 + $a ) :
		 
		 # iterators
		 # <>
		 '<>' eq $op ? scalar( readline $a ) :
		 
		 # dereferencing
		 # ${} @{} %{} &{} *{}
		 # '${}' eq $op ? $$a :
		 # '@{}' eq $op ? @$a :
		 # '%{}' eq $op ? %$a :
		 # '&{}' eq $op ? &$a :
		 # '*{}' eq $op ? *$a :
		 
		 croak( "Invalid operation '$op'" ) );
	    # This is the end of a really big ternary assignment in list context.
	    
	} # End of a while() over expressions.
	
	return( '""' eq $context ? ( "$accumulator" ) :
		'0+' eq $context ? ( 0 + $accumulator ) :
		'bool' eq $context ? ( !! $accumulator ) :
		croak( "Invalid context '$context' for finalizer" ) );
    };
}

1;

__END__

=head1 NAME

Data::Postponed - Delay the evaluation of expressions to allow post
facto changes to input variables

=head1 SYNOPSIS

 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # Will throw an error because 'foobar' can't be renamed anymore.
 $functions{foobar} = 'baz';

=head1 DESCRIPTION

This module allows you to delay the computation of values, usually so
you can change your mind about the returned value. Its a sort of time
travel.

The values returned by this module are overloaded objects which can be
operated on like numbers, strings, or booleans but aren't actually
made "real" until you use them in some context that requires that they
be computed first.

As an aide to debugging and to prevent time paradoxes, the default
postpone() function's effect is that once a value has been computed,
it ceases to be overloaded and all of the input variables to it are
turned read only.

=head1 Exportable functions

=over 4

=item postpone( EXPR )

=item postpone_once( EXPR )

=item postpone_forever( EXPR )

=back

=head1 Subclassing Data::Postponed

=head2 Overloadable methods

=over 4

=item Data::Postponed::...->new( EXPR )

This method must be overridden by a subclass. Data::Postponed comes
with three subclasses: L<Data::Postponed::OnceOnly>,
L<Data::Postponed::Once>, L<Data::Postponed::Forever> each of which
override this method.

Calling C<Data::Postponed->new( ... )> directly will produce an error.

=item $obj->Clone()

This method returns a new Data::Postponed object in the same subclass
equivalent to the current object. This implements the C<=> method for
L<overload>.

=back

=head3 Conversion operations

Each of the methods C<bool>, C<"">, C<0+> may be overridden. The base
class implementation evaluates all of the delayed computation with no
side effects and returns the computed value. If these methods are not
overridden, an overloaded value may be evaluated again in the future
and its result may be different.

The L<Data::Postponed::Forever> subclass does exactly this. No
overriding occurs and repeated evaluation of the overloaded value
always recalculates the returned value.

The L<Data::Postponed::Once> subclass overrides the conversion methods
so that once the value has been computed, it is finalized and will not
be recomputed again in the future.

The L<Data::Postponed::OnceOnly> subclass is L<Data::Postponed::Once>
except that it marks all of its input variables as read only after
this finalization has occurred. This provides you with an extra level
of security.

If you have a bug in your code and write to an input variable after
the postponed value has already been computed, you will receive an
error from perl that you have attempted to write to a read only
variable.

=head3 Postponed operations

=over 4

=item Non-assignment binary operations

All of the methods listed in the C<with_assign>, C<num_comparison>,
C<3way_comparison>, C<str_comparison>, C<binary> values of the
C<%overload::ops> hash. Also, the C<atan2> method from C<func>.

=item Non-assignment unary operations

The C<cos>, C<sin>, C<exp>, C<abs>, C<log>, C<sqrt> methods from
C<func>, the C<unary>, and the C<iterators> values of the
C<%overload::ops> hash.

=item Binary operations with assignment

All of the methods listed in the C<assign> value of the
C<%overload::ops> hash.

=item Unary operations with assignment

The C<mutator> methods from C<%overload::ops>.

=back

=head1 SEE ALSO

This is really similar to the I<Really> symbolic calculator from the
L<overload> documentation. This expands on that idea by adding the
::Once and ::OnceOnly subclasses and taking care to be generalized
instead of for just arithmetic.

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
