package Data::Postponed;
use strict;
use vars ( '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS',
           '@POSTPONERS', '@CLONERS', '@FINALIZERS',
           '%Objects', '%Values' );
use Carp ('carp', 'croak');
use Exporter;

BEGIN {
    $VERSION = 0.18;

    # Generate DEBUG.
    if ( $ENV{DATA_POSTPONED_DEBUG} or $^D ) {
	eval {
	    require Carp::Assert;
	    Carp::Assert->import;
	};
	if ( my $e = $@ ) {
	    eval( 'sub DEBUG () { !!0 }; 1' );
	}
    }
    else {
	eval( 'sub DEBUG () { !!0 }; 1' );
    }
    
    # Generate TRACE and DUMP_TRACE
    if ( $ENV{DATA_POSTPONED_TRACE} ) {
	eval( 'sub TRACE () { !!1 }; 1;' );
	eval( 'use Data::Dump::Streamer 1.11 ();'
	      . 'sub DUMP_TRACE () { !!1 };'
	      . '1;' );
	if ( my $e = $@ ) {
	    eval( 'sub DUMP_TRACE () { !!0 }; 1' );
	}
    }
    else {
	eval( 'sub TRACE () { !!0 }; sub DUMP_TRACE () { !!0 }; 1' );
    }
    
    *isa = \ &UNIVERSAL::isa;
    eval "sub PERLVER () { $] }";
}

######################################################################
#			  Debugging schtuph
######################################################################

sub _dump_literal {
    local $_ = shift;
    if ( not defined ) {
	return 'undef';
    }
    elsif ( \!!1 == \$_[0] ) {
    	return 'TRUE';
    }
    elsif ( \!!0 == \$_[0] ) {
    	return 'FALSE';
    }
#    elsif ( $_[0] =~ /^(?ix:[+-]?(?:\d+\.\d*|\d*\.\d+)(?:E[+-]?\d+)?)$/ ) {
    elsif ( /^(?ix:[+-]?(?:\d+\.?\d*|\d*\.\d+)(?:E[+-]+\d+)?)$/ ) {
	# The regex was taken from Regexp::Common $RE{num}{real},
	# simplified, and fixed. The original regex thought '.' was a
	# number.
	return "$_";
    }
    else {
	require Data::Dumper;
	return Data::Dumper::qquote( $_ );
    }
}

sub Dump {
    my $self = shift;
    @_ == 0
      or croak "Usage: ->Dump()";
    
    my $str = overload::StrVal( $self );
    
    DEBUG and
      assert( exists $Objects{$str},
	      "$str has a data store" );
    my $data = $Objects{$str};
    
    my $result;
    if ( 1 == @$data ) {
	if ( isa( ${$data->[0]}, __PACKAGE__ ) ) {
	    $result = Data::Postponed::Dump( ${$data->[0]} );
	}
	else {
	    $result = _dump_literal( ${$data->[0]} );
	}
    }
    else {
	my $a;
	if ( ! defined $data->[0] ) {
	}
	elsif ( isa( ${$data->[0]}, __PACKAGE__ ) ) {
	    $a = Data::Postponed::Dump( ${$data->[0]} );
	}
	else {
	    $a = _dump_literal( ${$data->[0]} );
	}
	
	my $b;
	if ( ! defined $data->[2] ) {
	}
	elsif ( isa( ${$data->[2]}, __PACKAGE__ ) ) {
	    $b = Data::Postponed::Dump( ${$data->[2]} );
	}
	else {
	    $b = _dump_literal( ${$data->[2]} );
	}
	
	
	if ( not defined $a ) { $a = "\$b" }
	elsif ( not defined $b ) { $b = "\$a" }
	
	my $op = $data->[1];
	$result = "($op $a $b)";
    }
    
    if ( defined wantarray ) {
	return $result;
    }
    else {
	print $result;
	# void context return
    }
}

######################################################################
#                          Function exports
######################################################################

BEGIN {
    *import = \ &Exporter::import;
    @EXPORT_OK = ( 'postpone',
		   'postpone_once',
		   'postpone_forever' );
    %EXPORT_TAGS = ( all => \ @EXPORT_OK );
}

sub postpone         { return Data::Postponed::OnceOnly->new( @_ ) }
sub postpone_once    { return Data::Postponed::Once    ->new( @_ ) }
sub postpone_forever { return Data::Postponed::Forever ->new( @_ ) }

# sub import {
#     my ( $pkg ) = @_;
    
#     # This is undocumented and I'm not sure its useful for anything. I
#     # have this here so I can play with it.
    
#     # Everything that isn't specifically meant for me is given to Exporter.
#     my ( @exports, $constant );
#     for ( @_[ 1 .. $#_ ] ) {
#         if ( not defined $constant
#            and
#            /^:(postpone(?:_forever|_once)?)$/ ) {
#           $constant = do { no strict 'refs';
#                            \ &$1 };
#           overload::constant( map { $_ => $constant }
#                               qw( integer float binary q qr ) );
#         }
#       else {
#           push @exports, $_;
#       }
#     }
    
#     if ( @exports ) {
#       __PACKAGE__->export_to_level( 2, $pkg, @exports );
#     }
    
#     1;
# }

######################################################################
#                         Object composition
######################################################################

# Objects are a scalar reference to nothing in particular. Their data
# is stored in the %Objects hash. It is accessed by each object's
# overload::Strval() value.

sub new {
    # A basic constructor. This creates a basic data store, inserts it
    # into %Objects, and returns the object which will be used as a
    # key to access that data.
    
    @_ == 2
      or croak "Usage: Data::Postponed::...->new( VALUE )";
    
    my $data = [ \ $_[1] ];
    my $self = bless \ do { my $v; $v }, $_[0];
    my $str = overload::StrVal( $self );
    
    TRACE and
      carp "$_[0]\->new $str.\n"
	. ( DUMP_TRACE
	    ? ( Data::Dump::Streamer::Dump()
		->Purity(0)
		->Data($_[1])
		->Out )
	    : "" );
    DEBUG and
      assert( ! exists $Objects{$str},
	      "Object store doesn't exist prior to creation" );
    
    $Objects{$str} = $data;
    
    return $self;
}

sub DESTROY {
    # A basic destructor. This removes the object's backing store from
    # %Objects.
    
    my $self = shift;
    my $str = overload::StrVal( $self );
    
    TRACE and
      carp "DESTROY $str";
    
    delete $Values{$str};
    if ( my $data = delete $Objects{$str} ) {
	# This branch is sometimes skipped if the global
	# $Objects{$str} was reaped during global cleanup. If it
	# doesn't exist, oh well.
	my $count = @$data;

	# Clear $data because it might contain a reference back to
	# $self.
	@$data = ();
	
	DEBUG and
	  assert( $count % 2 == 1,
		  "$str has N*2 + 1 items" );
	
	@$data = ();
    }
    
    return;
}

sub _Data {
    @_ == 1
      or croak "Usage \$obj->_Data()";
    
    my $self = shift;
    my $str = overload::StrVal( $self );

    TRACE and
      carp "_Data $str";
    DEBUG and
      assert( exists $Objects{$str},
	      "$str has a data store" );
    
    $Objects{overload::StrVal( $self )};
}

######################################################################
#                       Postponing operations
######################################################################

sub _IsBinary { shift() =~ /^(?:\+|\-|\*\*?|\/|\%|\<[\<\=]?|\>[\>\=]?|x|\.|[\!\=]\=|\<\=\>|cmp|l[te]|g[te]|eq|ne|\&|\||\^|atan2)$/ }

BEGIN {
    @POSTPONERS = ( map split( ' ' ),
		    '+ - * / % ** << >> x .',
#		    '+= -= *= /= %= **= <<= >>= x= .=',
		    '< <= > >= == !=',
		    '<=> cmp',
		    'lt le gt ge eq ne',
		    '& | ^',
#		    '&= |= ^=',
		    'atan2',
		    'neg ! ~',
		    'cos sin exp abs log sqrt' );
    
    for my $operation ( @POSTPONERS ) {
	no strict 'refs';
	*{"Data::Postponed::" . $operation} = sub {
	    # If I'm being asked to produce a final answer, I don't
	    # want to put work off anymore. So instead of punting, I
	    # return the finalized answer, now.
	    TRACE and
	      carp "Postponing $operation for " . overload::StrVal( $_[0] ) . "\n"
		. ( DUMP_TRACE
		    ? ( Data::Dump::Streamer::Dump( @_[ 1 .. $#_ ] )
			->Purity( 0 )
			->Out )
		    : "" );
	    
	    # Copy the value from $_[0] because -= assignment forms
	    # will overwrite it and my reference to the $_[0] on input
	    # will be transmogrified into a reference to the $_[0] on
	    # output.
	    #
	    # This will create a new object with a new data store with
	    # the initial value set to the Data::Postponed object that
	    # is currently involved in being postponed.
	    my $original = overload::StrVal( $_[0] );
	    my $new = ref( $_[0] )->new( undef );
	    my $str = overload::StrVal( $new );
	    
	    if ( DEBUG ) {
		assert( ! ref( ${$Objects{$str}[0]} )
			|| ! overload::Overloaded( ${$Objects{$str}[0]} )
			|| $str ne overload::StrVal( ${$Objects{$str}[0]} ),
			"Object's initial value is itself - infinite recursion" );
		assert( ! defined $_[2]
			|| $_[2] =~ /^1?$/,
			"'inverted' parameter is undef, TRUE, or FALSE" );
		assert( exists $Objects{$str},
			"$str has a data store" );
		assert( @{$Objects{$str}} % 2 == 1,
			"$str has N*2 + 1 items" );
	    }
	    
	    # Now modify this object so it contains the old value, the
	    # operation, and if it is a binary operation, the new
	    # value to operate on.
	    my $self = shift;
	    @{$Objects{$str}}
	      = ($_[1] ? # inverted-p
		 
		 # Inverted binary.
		 ( _MaybeRef( $self, $_[0] ), $operation, \ $self ) :
		 
		 ( ! _IsBinary( $operation ) ? # binary-p
		   
		   # Unary operation
		   ( \ $self, $operation, undef ) :
		   
		   ( defined( $_[1] ) ? # non-assignment-p
		     
		     # Non-assignment binary
		     ( \ $self, $operation, _MaybeRef( $self, $_[0] ) ) :
		     
		     # Assignment binary
		     ( \ $self, $operation, _MaybeRef( $self, $_[0] ) ) ) ) );
	    
	    return $new;
	    
	    # FIXME!!  I thought the following code was required to
	    # prevent postponing during finalization but it appears
	    # this never happens. If it turns out that I need it, I'm
	    # leaving the code here.
	    
	    # Examine the call stack starting with my parent and the
	    # @_ for any calls to Data::Postponed::_Finalize to see if
	    # the the $_[0] present here is the same $_[0] present
	    # there. If so, then I really ought not to be postponing
	    # this object and should be sure to return the finalized
	    # value, not a postponed object.
	    #
	    # See perldebguts for caller() in list context, declared
	    # in the DB package.
#	    my $IsFinalizing;
#	    for ( my $cx = 1;
#		  my ( $function ) = ( caller $cx )[ 3 ];
#		  ++ $cx ) {
#		if ( $function eq 'Data::Postponed::_Finalize' ) {
#		    $IsFinalizing = !!1;
#		    last;
#		}
#	    }
#
#	    return( $IsFinalizing
#		    ? &{ref( $new ) . "::_Finalize"}( $new )
#		    : $new );
	};
    }
}

sub _MaybeRef {
    if ( isa( $_[0], __PACKAGE__ )
	 and isa( $_[1], __PACKAGE__ )
	 and overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] ) ) {
	return undef;
    }
    else {
	return \ $_[1];
    }
}

######################################################################
#                         Cloning operation
######################################################################

# I'm not aware of any other function that is valid to use here so I'm
# not bothering to put '=' in an array and make it visible.

BEGIN {
    @CLONERS = '=';
    
    {
	no strict 'refs';
	*{"Data::Postponed::="} = sub  {
	    my $original = overload::StrVal( $_[0] );
	    # Clone the given object. This is like creating a new
	    # object except it doesn't add anything to the stack.
	    
	    # the undef is discarded shortly.
	    my $new = ref( $_[0] )->new( undef );
	    my $new_str = overload::StrVal( $new );
	    
	    TRACE and
	      carp "CLONE $original -> $new_str"
		. ( DUMP_TRACE
		    ? ( Data::Dump::Streamer::Dump()
			->Purity(0)
			->Data( $_[0], $new )
			->Out )
		    : "" );
	    
	    # Copy @{$Objects{$original}} into @$data but replace any
	    # instances of self-reference from $self to be self-ref
	    # for the new object.
	    @{$Objects{$new_str}} = @{$Objects{$original}};
#	    my $SelfRef;
# 	    for ( grep +( 'REF' eq ref()
#			  && isa( $$_, __PACKAGE__ )
#			  && $original eq overload::StrVal( $$_ ) ),
# 		  @{$Objects{$new_str}} ) {
#		$SelfRef = !!1;
# 		$_ = undef;#\ $new;
# 	    }
	    
	    if ( DEBUG ) {
		assert( exists $Objects{$original},
			"The cloned object, $original, has a data store" );
		assert( @{$Objects{$original}} % 2 == 1,
			"The original data store has N*2+1 elements" );
		assert( exists $Objects{$new_str},
			"The clone, $new_str, has a data store" );
		assert( @{$Objects{$new_str}} % 2 == 1,
			"The cloned data store has N*2+1 elements" );
#		if ( $SelfRef ) {
#		    assert( grep( ( 'REF' eq ref()
#				    && isa( $$_, __PACKAGE__ )
#				    && $new_str eq overload::StrVal( $$_ ) ),
#				  @{$Objects{$new_str}} ),
#			    "The original had self reference and so does the clone." );
#		}
	    }
	    
	    return $new;
	};
    }
}

######################################################################
#                        Finalizing operation
######################################################################

BEGIN {
    @FINALIZERS = ( '""', '0+', 'bool',
		    
		    # 5.6.x+ added overloadable <> and various dereferencing 
		    ( PERLVER > 5.005
		      ? ( '<>',
			  '${}', '@{}', '%{}', '&{}', '*{}' )
		      : () ) );
    no strict 'refs';
    
    # conv
    *{'Data::Postponed::""'}   = sub {
	no strict 'refs';
        local $_ = &{$_[0]->can( '_Finalize' )};
	
	DEBUG and
	  assert( ! isa( $_, __PACKAGE__ ),
		  "_Finalize( OBJ ), finalized" );
	
	return "$_";
    };
    
    *{'Data::Postponed::0+'}   = sub {
	no strict 'refs';
        local $_ = &{$_[0]->can( '_Finalize' )};
	
	DEBUG and
	  assert( ! isa( $_, __PACKAGE__ ), 
		  "_Finalize( OBJ ), finalized" );
	
	0+$_;
    };
    
    *{'Data::Postponed::bool'} = sub {
	no strict 'refs';
        local $_ = &{$_[0]->can( '_Finalize' )};
	
	DEBUG and
	  assert( ! isa( $_, __PACKAGE__ ), 
		  "_Finalize( OBJ ), finalized" );
	
	!!$_;
    };
    
    # These methods were not overloadable until after 5.5.x
    if ( PERLVER > 5.005 ) {
	# iterators
	*{'Data::Postponed::<>'}   = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return readline( ref()
			     ? $_
			     : do { no strict 'refs';
				    caller() . "::$_" } );
	};
	
	# dereferencing
	*{'Data::Postponed::${}'}  = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return( ref()
		    ? $_
		    : do { no strict 'refs';
			   \${ caller() . "::$_" } } );
	};
	
	*{'Data::Postponed::@{}'}  = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return( ref()
		    ? $_
		    : do { no strict 'refs';
			   \@{ caller() . "::$_" } } );
	};
	
	*{'Data::Postponed::%{}'}  = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return( ref()
		    ? $_
		    : do { no strict 'refs';
			   \%{ caller() . "::$_" } } );
	};
	
	*{'Data::Postponed::&{}'}  = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return( ref()
		    ? $_
		    : do{ no strict 'refs';
			  \&{caller() . "::$_"} } );
	};
	
	*{'Data::Postponed::*{}'}  = sub {
	    no strict 'refs';
	    local $_ = &{$_[0]->can( '_Finalize' )};
	    
	    DEBUG and
	      assert( ! isa( $_, __PACKAGE__ ), 
		      "_Finalize( OBJ ), finalized" );
	    
	    return( ref()
		    ? $_
		    : do { no strict 'refs';
			   \*{caller() . "::$_" } } );
	};
    }
    
    if ( TRACE ) {
	for my $operation ( @FINALIZERS ) {
	    no strict 'refs';
	    BEGIN { $^W = 0 }
	    my $original = \ &{"Data::Postponed::$operation"};
	    *{"Data::Postponed::$operation"} = sub {
		carp "FINALIZE $operation for " .  overload::StrVal( $_[0] );
                my ( @out, $out );
                if ( wantarray ) {
                    @out = &$original;
                }
                elsif ( defined wantarray ) {
                    $out = &$original;
                }
                else {
                    &$original;
                }
                carp "<< FINALIZE $operation for " . overload::StrVal( $_[0] );
                return( wantarray ? @out[ 0 .. $#out ] :
                        defined( wantarray ) ? $out :
                        () );
	    };
	}
    }
}

sub A () { 0 }
sub OP () { 1 }
sub B () { 2 }

sub _Finalize {
    # If I've been asked to finalize something that is not a
    # Data::Postponed object, then it already final and I just return
    # it.
    if ( ! isa( $_[0], __PACKAGE__ ) ) {
	TRACE and
	  warn "<- $_[0]\n";
	#	TRACE and
	#	  warn "Done, not postponed.";
 	return $_[0];
    }
    
    my $self = $_[0];
    my $str = overload::StrVal( $self );
    my $data = $Objects{$str};
    
    TRACE and
      warn "_Finalize for $str\n";
    
    if ( DEBUG ) {
	assert( exists $Objects{$str},
		"$str has a data store" );
	assert( @{$Objects{$str}} % 2 == 1,
		"$str has N*2+1 items" );
    }
    
    # Do any value copying necessary for binary operations.
    if ( @$data > 1 and
	 _IsBinary( $data->[OP] ) ) {
	if ( not defined $data->[B] ) {
	    $data->[B] = $data->[A];
	}
	if ( DEBUG ) {
	    assert( defined $data->[A],
		    "\$data->[A] is defined for binary op" );
	    assert( defined $data->[B],
		    "\$data->[B] is defined for binary op" );
	}
    }
    else {
	if ( DEBUG ) {
	    assert( defined $data->[A],
		    "\$data->[A] is defined for unary op" );
	}
    }
    
    $Values{$str} = ( isa( ${$data->[0]}, __PACKAGE__ )
		      ? ${$data->[0]}->can('_Finalize')->( ${$data->[0]} )
		      : ${$data->[0]} );
    
    # For each operation, execute it and update the intermediate value
    # computed thus far.
    for ( my $ix = 1;
 	  $ix < $#$data;
 	  $ix += 2 ) {
	my $op = $data->[$ix];
	my $b;
	if ( _IsBinary( $op ) ) {
	    $b = ( isa( ${$data->[$ix+1]}, __PACKAGE__ )
		   ? ${$data->[$ix+1]}->can('_Finalize')->( ${$data->[$ix+1]} )
		   : ${$data->[$ix+1]} );
	}
	
	if ( DEBUG ) {
	    if ( _IsBinary( $op ) ) {
		assert( ref( $data->[$ix+1] ),
			"\$value is a reference" );
	    }
	    else {
		assert( ! defined $b,
			"\$value is empty" );
	    }
 	}
	
	{
	    local $SIG{__WARN__} ||= \ &Carp::cluck;
	    local $SIG{__DIE__} ||= \ &Carp::confess;
	    
	    $Values{$str} =
	      ( ( $op eq '+'   ) ? ( $Values{$str} +   $b ) :
		( $op eq '-'   ) ? ( $Values{$str} -   $b ) :
		( $op eq '*'   ) ? ( $Values{$str} *   $b ) :
		( $op eq '/'   ) ? ( $Values{$str} /   $b ) :
		( $op eq '%'   ) ? ( $Values{$str} %   $b ) :
		( $op eq '**'  ) ? ( $Values{$str} **  $b ) :
		( $op eq '<<'  ) ? ( $Values{$str} <<  $b ) :
		( $op eq '>>'  ) ? ( $Values{$str} >>  $b ) :
		( $op eq 'x'   ) ? ( $Values{$str} x   $b ) :
		( $op eq '.'   ) ? ( $Values{$str} .   $b ) :
		( $op eq '<'   ) ? ( $Values{$str} <   $b ) :
		( $op eq '<='  ) ? ( $Values{$str} <=  $b ) :
		( $op eq '>'   ) ? ( $Values{$str} >   $b ) :
		( $op eq '>='  ) ? ( $Values{$str} >=  $b ) :
		( $op eq '=='  ) ? ( $Values{$str} ==  $b ) :
		( $op eq '!='  ) ? ( $Values{$str} !=  $b ) :
		( $op eq '<=>' ) ? ( $Values{$str} <=> $b ) :
		( $op eq 'cmp' ) ? ( $Values{$str} cmp $b ) :
		( $op eq 'lt'  ) ? ( $Values{$str} lt  $b ) :
		( $op eq 'le'  ) ? ( $Values{$str} le  $b ) :
		( $op eq 'gt'  ) ? ( $Values{$str} gt  $b ) :
		( $op eq 'ge'  ) ? ( $Values{$str} ge  $b ) :
		( $op eq 'eq'  ) ? ( $Values{$str} eq  $b ) :
		( $op eq 'ne'  ) ? ( $Values{$str} ne  $b ) :
		( $op eq '&'   ) ? ( $Values{$str} &   $b ) :
		( $op eq '|'   ) ? ( $Values{$str} |   $b ) :
		( $op eq '^'   ) ? ( $Values{$str} ^   $b ) :
		
		# Several functions in Data::Postponed are named
		# abs(), int(), etc. I have to write CORE::foo() to
		# call the real function instead of the local one.
		( $op eq 'atan2' ) ? ( CORE::atan2( $Values{$str}, $b ) ) :
		( $op eq 'neg'  ) ? ( - $Values{$str} ) :
		( $op eq '!'    ) ? ( ! $Values{$str} ) :
		( $op eq '~'    ) ? ( ~ $Values{$str} ) :
		( $op eq 'cos'  ) ? ( CORE::cos $Values{$str} ) :
		( $op eq 'sin'  ) ? ( CORE::sin $Values{$str} ) :
		( $op eq 'exp'  ) ? ( CORE::exp $Values{$str} ) :
		( $op eq 'abs'  ) ? ( CORE::abs $Values{$str} ) :
		( $op eq 'log'  ) ? ( CORE::log $Values{$str} ) :
		( $op eq 'sqrt' ) ? ( CORE::sqrt $Values{$str} ) :
		croak( "$op isn't an implemented operation by Data::Postponed" ) );
	}
	
 	 DEBUG and
 	    assert( ! ref($Values{$str})
 		    || ! overload::Overloaded( $Values{$str} )
 		    || isa( $Values{$str}, __PACKAGE__ ),
 		    "Intermediate value of \$Values{$str} is not postponed" );
    }
    
    DEBUG and
      assert( ! ref($Values{$str})
	      || ! overload::Overloaded( $Values{$str} )
	      || isa( $Values{$str}, __PACKAGE__ ),
	      "Final value of \$Values{$str} is not postponed" );

    TRACE and
      warn "<== $Values{$str}\n";
    return delete $Values{$str};
}

######################################################################
#                           Overload magic
######################################################################

use overload
  (# Hook all the non-finalizing operations which will be stored
   # internally as "stuff to do" when a finalizing operation is
   # detected.
   
   # These are the pure-value changing methods. The original object
   # isn't modified so I just return a new object including the new
   # value and an operation.
   map( { $_ => $_ }#do { no strict 'refs';
	#	#     \ &{__PACKAGE__ . "::$_"} } }
	@POSTPONERS,
	@CLONERS,
	@FINALIZERS ),
   fallback => 1 );

use Data::Postponed::Forever;
use Data::Postponed::Once;
use Data::Postponed::OnceOnly;

1;

__END__


=head1 NAME

Data::Postponed - Delay the evaluation of expressions to allow post
facto changes to input variables

=head1 SYNOPSIS

Postponing changes with postpone()

 use Data::Postponed 'postpone';
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # Will throw an error because 'foobar' can't be renamed anymore.
 $functions{foobar} = 'baz';

Postponing changes with postpone_once()

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

Postponing changes with postpone_forever()

 use Data::Postponed 'postpone_forever';
 
 %functions = ( foobar => 'foo' );
 
 $code = "sub " . postpone_forever( $functions{foobar} ) . " { return time }";
 $functions{foobar} = "baz";
 
 # Reflects the new name of 'bar' instead of 'foo';
 print $code;
 
 # Continues to reflect changes to the input variables
 $functions{foobar} = "quux";
 print $code;

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

=head1 DEBUGGING

=over 4

=item Data::Postponed::Dump( EXPR )

The function C<Data::Postponed::Dump> may be called on a
Data::Postponed object / expression to produce a dump of the structure
of a postponed object. It is pseudo-lisp.

When called in void context, it prints its output to the currently
selected filehandle, normally STDOUT.

When called in scalar or list context, it returns its output as a
string.

=item DATA_POSTPONED_DEBUG

C<Data::Postponed> enables assertions if the environment variable
DATA_POSTPONED_DEBUG is true, if $^P is true, or if perl was invoked
with the -d parameter.

If the module L<Carp::Assert> cannot be loaded, assertions are not
enabled.

=item DATA_POSTPONED_TRACE

C<Data::Postponed> uses L<Carp>::cluck() to report the execution and
progress of the module.

If the module L<Data::Dump::Streamer> can be loaded, some values will
be dumped as well.

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
