use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'                      => 'RUNONCE',
    'DISTNAME'          => 'RunOnce',
    'VERSION_FROM'      => 'RUNONCE.pm', # finds $VERSION
    'PREREQ_PM'     => { IO => 1.18 },
    'dist'                  => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'realclean' => {
	'FILES' => 'Makefile.old Makefile pod*'
    }
);

