package Data::Postponed::Util::NoLonger;
use strict;
use overload( map( { $_ => \ &Value }
                   split( ' ', $overload::ops{conversion} ) ),
	      fallback => 1 );
use vars '%Value';

sub steal {
    my ( $class ) = @_;
    my $obj = bless $_[1], $class;
    my $str = overload::StrVal( $obj );
    $Value{$str} = \ $_[2];
    return undef;
}

sub Value {
    my ( $self ) = @_;
    my $str = overload::StrVal( $self );
    return ${$Data::Postponed::NoLonger::Value{$str}};
}

sub DESTROY {
    my ( $self ) = @_;
    my $str = overload::StrVal( $self );
    delete $Data::Postponed::NoLonger::Value{$str};
    return;
}

1;
