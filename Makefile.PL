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
                 'Test::More' => 0,
		},
);

if ( $] <= 5.6 ) {
    # I observed that 5.005.04 couldn't load B while PERL_DL_NONLAZY
    # was turned on. This is the default from Test::Harness. Since
    # this would normally cause all the tests to fail, I'm manually
    # editing the Makefile to remove the flag.

    # PERL_DL_NONLAZY=1 perl -MB -e1

    # Can't load
    # '/home/josh/perl5.005_04/lib/5.00504/i686-linux/auto/B/B.so' for
    # module B:
    # /home/josh/perl5.005_04/lib/5.00504/i686-linux/auto/B/B.so:
    # undefined symbol: Perl_byterun at
    # /home/josh/perl5.005_04/lib/5.00504/i686-linux/DynaLoader.pm
    # line 169.
    #  at -e line 0
    # BEGIN failed--compilation aborted.

    open MAKE, "< Makefile" or die "Couldn't open Makefile for reading: $!";
    @make = <MAKE>;
    close MAKE or die "Couldn't close Makefile after reading: $!";

    s/PERL_DL_NONLAZY=1// for @make;

    open MAKE, "> Makefile" or die "Couldn't open Makefile for writing: $!";
    print MAKE @make or die "Couldn't write to Makefile: $!";;
    close MAKE or die "Couldn't close Makefile and flush buffer: $!";
}

