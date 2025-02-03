# helpers.pm - Shared testing routines
#
# Ryan Thompson <i@ry.ca> 2025

package Local::TestRoutines;

use v5.38;
use Test2::V0;
use Exporter;
use Hash::Merge qw< merge >;
use File::Copy;
use File::Temp qw< tempfile >;
use Carp;
use autodie;

our @ISA = qw< Exporter >;
our @EXPORT = qw< t_dbfile t_config t_db_run_on_copy >;

my $base = $ENV{PWC_TEST_DIR} // 't/_tests';
my $sample_base = 't/sample';

mkdir $base unless -d $base;
ok -d $base, "Base test file directory ($base) is a directory";

# Generate a different $dbfile for each test, named according to .t filename
sub t_dbfile($unlink = 1) {
    my ($package, $filename, $caller) = caller;
    $filename =~ m!/([^/]+?)\.t! or croak "Unknown filename format: $filename";
    my $dbfile = "$base/pwc_$1.sqlite";
    unlink $dbfile if $unlink and -f $dbfile;
    return "$base/pwc_$1.sqlite";
}

# Generate a compliant config for testing, but you may supply %overrides
# which will be deeply merged
sub t_config(%overrides) {
    no warnings 'qw';
    my $base = 't/sample';
    my %default = (
        repo    => {
            'pwc-club' => "$sample_base/perlweeklychallenge-club",
            'pwc'      => "$sample_base/perlweeklychallenge",
        },
        dbfile  => "$sample_base/read_tests.sqlite",
        lang    => {
            perl    => {
                aliases     => [ 'perl5' ], 
                extensions  => [ qw< pl p5 perl > ],
                score       => 2,
            },
            raku    => {
                aliases     => [ 'perl6' ],
                extensions  => [ qw< p6 raku > ],
                score       => 2,
            }
        },
        blog    => { score => 2 },
        color   => [ qw<
            rgb(209,177,135)
            rgb(199,123,88)
            rgb(174,93,64)
            rgb(121,68,74)
            rgb(75,61,68)
            rgb(186,145,88)
        > ],
    );

    merge( \%default, \%overrides );
}

# Make a copy of the read-only database, pass its filename to the
# provided $code function, and unlink it when we're done
sub t_db_run_on_copy :prototype(&) {
    my ($code) = @_;
    my ($fb, $dbfile) = tempfile("pwc_XXXXX", SUFFIX => ".sqlite");
    copy( "$sample_base/read_tests.sqlite" => $dbfile );
    $code->($dbfile)
}

1;
