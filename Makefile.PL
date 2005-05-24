#!perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   AUTHOR => '"Joshua ben Jore" <jjore@cpan.org>',
   SIGN => 1,

   ABSTRACT_FROM => 'lib/Data/Postponed.pm',
   NAME => "Data::Postponed",
   PREREQ_PM => {
		 # Core modules for runtime
		 overload => 0,
		 strict => 0,
		 vars => 0,
		 Carp => 0,
		 Exporter => 0,
		 
		 # Debugging
		 # Carp::Assert => 0,
		 
		 # Tracing with content dumps
		 # Data::Dump::Streamer => 1.11
		 
		},
   VERSION_FROM => 'lib/Data/Postponed.pm',
  );
