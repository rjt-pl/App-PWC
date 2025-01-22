use v5.38;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

my %WriteMakefileArgs = (
    NAME                => 'App::PWC',
    AUTHOR              => q{Ryan Thompson <i@ry.ca>},
    VERSION_FROM        => 'lib/App/PWC.pm',
    ABSTRACT_FROM       => 'lib/App/PWC.pm',
    LICENSE             => 'artistic_2',
    MIN_PERL_VERSION    => '5.038',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'    => '0',
        'Test2::V0'     => '0',
    },
    PREREQ_PM => {
        'Compress::Zlib'    => 0,
        'Logfile::Rotate'   => '1.04',
        'DBI'               => '1.644',     # CVE-2014-1040[12]
        'File::Slurper'     => 0,
        'YAML::PP',         => '0.38.0',    # Builtin booleans
        'Log::Log4perl'     => '1.57',
        'YAML',             => 0,
        'Dancer2',          => '1.1.2',
    },
    # XXX - xt tests should only be run on make release, not 
    # for a regular build.
    test  => { TESTS => join ' ', 't/*.t', 'xt/*.t', 't/0*/*.t' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-PWC-*' },

    META_MERGE      => {
        resources => {
            'meta-spec' => { version => 2 },
            repository  => 'https://github.com/rjt-pl/App-PWC.git',
            bugtracker  => 'https://github.com/rjt-pl/App-PWC/issues',
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
