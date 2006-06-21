#!perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR => '"Joshua ben Jore" <jjore@cpan.org>',
    SIGN   => 1,

    ABSTRACT_FROM => 'lib/Data/Postponed.pm',
    NAME          => "Data::Postponed",
    PREREQ_PM     => {

        # Debugging
        # Carp::Assert => 0,

        # Tracing with content dumps
        # Data::Dump::Streamer => 1.11

        'Scalar::Util' => 0,
    },
    VERSION_FROM => 'lib/Data/Postponed.pm',
);
