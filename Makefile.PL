use ExtUtils::MakeMaker;
WriteMakefile
  (
   AUTHOR => '"Joshua ben Jore" <jjore@cpan.org>',
   SIGN => 1,
   
   NAME => 'Data::Postponed',
   VERSION_FROM => 'lib/Data/Postponed.pm',
   ABSTRACT_FROM => 'lib/Data/Postponed.pm',
   
   PREREQ_PM => {
		 'strict' => 0,
		 'vars' => 0,
		 'overload' => 0,
		 'B' => 0,
		 'Carp' => 0,
		 'Exporter' => 0,
		},
);
