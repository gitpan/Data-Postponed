#!perl
use Test::More tests => 6;
use strict;
BEGIN {
    $ENV{DATA_POSTPONED_DEBUG} = 1;
}
use Data::Postponed 'postpone_forever';

{
    my $o = postpone_forever( 1 );
    my $c = overload::Method( $o, '+' );
    ok( $c, 'Can("=")' );
}

{
    my $o = postpone_forever( 1 );
    my $c = $o->overload::Method( '=' );
    ok( My::eq_array( $o->_Data,
		      &{$c}($o)->_Data ),
	"No references" );
}

{
    my $o = postpone_forever( \ 1 );
    my $c = $o->overload::Method( '=' );
    ok( My::eq_array( $o->_Data,
		      &{$c}($o)->_Data ),
	"Plain references" );
}

{
    my $o = postpone_forever( T->new );
    my $c = $o->overload::Method( '=' );
    ok( My::eq_array( $o->_Data,
		      &{$c}($o)->_Data ),
	"Overloaded references" );
}

{
    my $o = postpone_forever( "a" );
    # Add a simple OBJ . VAL onto the stack.
    
    $o = $o . $o;
    my $c = $o->overload::Method( '=' );
    
    ok( My::eq_array( $o->_Data,
		      &{$c}($o)->_Data ),
	"Self reference / binary" );
}

{
    my $o = postpone_forever( "a" );
    
    $o .= $o;
    my $c = $o->overload::Method( '=' );
    
    ok( My::eq_array( $o->_Data,
		      &{$c}($o)->_Data ),
	"Self reference / assignment" );
}

package T;
use overload( '""' => sub { "String" } );
sub new { bless [], "T" }

package My;
my $DNE;
BEGIN { $DNE = bless [], 'Does::Not::Exist' }

sub eq_array {
    local @My::Data_Stack;
    local %My::Refs_Seen;
    _eq_array(@_);
}

sub _type {
    my $thing = shift;

    return '' if !ref $thing;

    for my $type (qw(ARRAY HASH REF SCALAR GLOB Regexp)) {
        return $type if UNIVERSAL::isa($thing, $type);
    }

    return '';
}

sub _overloaded {
    return
      ref( $_[0] )
	and overload::Overloaded( $_[0] );
}

sub _av_elt {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $val = \$_[0][$_[1]];
	eval { bless $_[0], $class };
	return $$val;
    }
    else {
	return $_[0][$_[1]];
    }
}

sub _av_top {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $top = \ $#{$_[0]};
        eval { bless $_[0], $class };
	return $$top;
    }
    else {
	return $#{$_[0]};
    }
}

sub _hv_keys {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	
	my ( @out, $out );
	if ( wantarray ) {
	    @out = keys %{$_[0]};
	}
	elsif ( defined wantarray ) {
	    $out = keys %{$_[0]};
	}
	
	eval { bless $_[0], $class };
	
	return( wantarray ? @out[ 0 .. $#out ] :
		defined( wantarray ) ? $out :
		() );
    }
    else {
	return keys %{$_[0]};
    }
}

sub _hv_exists {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $exists = exists $_[0]{$_[1]};
	eval { bless $_[0], $class };
	return $exists;
    }
    else {
	return exists $_[0]{$_[1]};
    }
}

sub _hv_elt {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $val = \ $_[0]{$_[1]};
	eval { bless $_[0], $class };
	return $$val;
    }
    else {
	return $_[0]{$_[1]};
    }
}

sub _sv_deref {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $val = \ ${$_[0]};
	eval { bless $_[0], $class };
	return $$val;
    }
    else {
	return ${$_[0]};
    }
}

sub _sv_num {
    if ( _overloaded( $_[0] ) ) {
	my ( $class ) = ref( $_[0] ) =~ /^(.+)=/;
	eval { bless $_[0], 'Does::Not::Exist' };
	my $num = 0 + $_[0];
	eval { bless $_[0], $class };
	return $num;
    }
    else {
	return 0+$_[0];
    }
}

sub _sv_str {
    if ( _overloaded( $_[0] ) ) {
	return overload::StrVal( $_[0] );
    }
    else {
	return "$_[0]";
    }
}

sub _eq_hash {
    my($a1, $a2) = @_;
    
    if( grep !_type($_) eq 'HASH', $a1, $a2 ) {
        warn "eq_hash passed a non-hash ref";
        return 0;
    }
    
    return 1 if _sv_str( $a1 ) eq _sv_str( $a2 );
    
    if( $My::Refs_Seen{_sv_str($a1)} ) {
        return $My::Refs_Seen{_sv_str($a1)} eq _sv_str($a2);
    }
    else {
        $My::Refs_Seen{_sv_str($a1)} = _sv_str($a2);
    }
    
    my $ok = 1;
    my $bigger = _hv_keys($a1) > _hv_keys($a2) ? $a1 : $a2;
    foreach my $k (_hv_keys( $bigger )) {
        my $e1 = _hv_exists( $a1, $k ) ? _hv_elt( $a1, $k ) : $DNE;
        my $e2 = _hv_exists( $a2, $k ) ? _hv_elt( $a2, $k ) : $DNE;
	
        push @My::Data_Stack, {
			   type => 'HASH',
			   idx => $k,
			   vals => [$e1, $e2]
			  };
        $ok = _deep_check($e1, $e2);
        pop @My::Data_Stack if $ok;
	
        last unless $ok;
    }
    
    return $ok;
}

sub _deep_check {
    my($e1, $e2) = @_;
    my $ok = 0;

    {
        # Quiet uninitialized value warnings when comparing undefs.
        local $^W = 0;

        # Either they're both references or both not.
        my $same_ref = !(!ref $e1 xor !ref $e2);

        if( defined($e1) xor defined($e2) ) {
            $ok = 0;
        }
        elsif ( ( _sv_num( $e1 ) == $DNE ) xor ( _sv_num( $e2 ) == $DNE ) ) {
            $ok = 0;
        }
        elsif ( $same_ref and (_sv_str($e1) eq _sv_str($e2)) ) {
            $ok = 1;
        }
        else {
            my $type = _type($e1);
            $type = '' unless _type($e2) eq $type;

            if( !$type ) {
                push @My::Data_Stack, { vals => [$e1, $e2] };
                $ok = 0;
            }
            elsif( $type eq 'ARRAY' ) {
                $ok = _eq_array($e1, $e2);
            }
            elsif( $type eq 'HASH' ) {
                $ok = _eq_hash($e1, $e2);
            }
            elsif( $type eq 'REF' ) {
                push @My::Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check(_sv_deref($e1), _sv_deref($e2));
                pop @My::Data_Stack if $ok;
            }
            elsif( $type eq 'SCALAR' ) {
                push @My::Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check(_sv_deref($e1), _sv_deref($e2));
                pop @My::Data_Stack if $ok;
            }
        }
    }

    return $ok;
}

sub _eq_array  {
    my($a1, $a2) = @_;

    if( grep !_type($_) eq 'ARRAY', $a1, $a2 ) {
        warn "eq_array passed a non-array ref";
        return 0;
    }
    
    return 0
      if _overloaded( $a1 ) xor _overloaded( $a2 );
    
    return 1
      if _sv_str( $a1 ) eq _sv_str( $a2 );
    
    if($My::Refs_Seen{_sv_str( $a1 )}) {
        return $My::Refs_Seen{_sv_str( $a1 )} eq _sv_str( $a2 );
    }
    else {
        $My::Refs_Seen{_sv_str( $a1 )} = _sv_str( $a2 );
    }

    my $ok = 1;
    my $max = _av_top( $a1 ) > _av_top( $a2 ) ? _av_top( $a1 ) : _av_top( $a2 );
    for (0..$max) {
        my $e1 = $_ > _av_top( $a1 ) ? $DNE : _av_elt( $a1, $_ );
        my $e2 = $_ > _av_top( $a2 ) ? $DNE : _av_elt( $a2, $_ );
	
        push @My::Data_Stack, { type => 'ARRAY',
			    idx => $_,
			    vals => [$e1, $e2] };
        $ok = _deep_check($e1,$e2);
        pop @My::Data_Stack if $ok;
	
        last unless $ok;
    }
    
    return $ok;
}

