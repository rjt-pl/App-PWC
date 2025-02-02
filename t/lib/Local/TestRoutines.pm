# helpers.pm - Shared testing routines
#
# Ryan Thompson <i@ry.ca> 2025

package Local::TestRoutines;

use v5.38;
use Test2::V0;
use Exporter;
use Carp;
use autodie;

our @ISA = qw< Exporter >;
our @EXPORT = qw< t_dbfile >;

my $base = $ENV{PWC_TEST_DIR} // 't/_tests';

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

1;
