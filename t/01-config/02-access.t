use v5.38;
use Test2::V0 -target => 'App::PWC::Config';
use lib qw< t/lib >;
use Local::TestRoutines;

my $conf = CLASS->new( conf => t_config );

# Check that config has some basic things we expect to see there.
# Not necessary to validate ALL of the file, and better if we don't.
is   $conf->repo('pwc')         => 't/sample/perlweeklychallenge';
like $conf->color(0),qr/^rgb\(/ => 'First color is a color';

my @colors = $conf->color;
like $colors[0], qr/^rgb\(/     => 'First color is a color (array)';
ok   @colors > 1                => 'Colors has more than one element';

my $cit = $conf->color_iterator;
my %seen;
my $undefs = 0;
# We will never have a default config with more colors than this!
for (1..1000) {
    my $color = $cit->();
    $seen{$color}++;
    $undefs++ if not defined $color;
}
my $first_color = $conf->color(0);

ok $seen{$first_color} > 1      => 'We loop around';
is $undefs, 0                   => 'All colors have defined values';

done_testing;
