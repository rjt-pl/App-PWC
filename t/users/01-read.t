#!perl -T

use Test2::V0 -target => 'App::PWC::Users';
use App::PWC::Config;

my $conf  = App::PWC::Config->new( config_file => 'config/pwc.yaml' );
my $users = CLASS()->new( conf => $conf );

is $users->realname('ryan-thompson'), 'Ryan Thompson', 'I exist!';
is $users->realname('amanda-not-b-found'), undef, 'Nonexistent user undef';

my %members;
ok lives { %members = $users->members }, '$users->members works';
is $members{'ryan-thompson'}, 'Ryan Thompson', '$members contains me';

my %guests;
ok lives { %guests = $users->guests }, '$users->guests works';
is $guests{'szabgab'}, 'Gabor Szabo', '$guests contains Gabor';

done_testing;
