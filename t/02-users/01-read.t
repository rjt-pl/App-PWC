use v5.38;
use Test2::V0 -target => 'App::PWC::Users';
use App::PWC::Config;

# Normally this comes from Dancer, but we'll supply our own.
my $conf_hash = {
    repo => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
};

my $conf  = App::PWC::Config->new( conf => $conf_hash );
my $users = CLASS()->new( conf => $conf );

is $users->realname('ryan-thompson'), 'Ryan Thompson', 'I exist!';
is $users->realname('amanda-not-b-found'), undef, 'Nonexistent user undef';

my $members;
ok lives { $members = $users->members }, '$users->members works';
is $members->{'ryan-thompson'}, 'Ryan Thompson', '$members contains me';

my $guests;
ok lives { $guests = $users->guests }, '$users->guests works';
is $guests->{'szabgab'}, 'Gabor Szabo', '$guests contains Gabor';

done_testing;
