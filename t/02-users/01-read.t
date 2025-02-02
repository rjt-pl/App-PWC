use v5.38;
use Test2::V0 -target => 'App::PWC::Users';
use App::PWC::Config;

# Normally this comes from Dancer, but we'll supply our own.
my $conf_hash = {
    repo    => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
    dbfile  =>   't/sample/read_tests.sqlite',
};

my $conf  = App::PWC::Config->new( conf => $conf_hash );
my $users = CLASS()->new(          conf => $conf      );

my $user = $users->get('ash');
is ref($users->get('ash')), 'App::PWC::User'  => 'User ash exists';
is      $user->realname,    'Andrew Shitov'   => 'Real name lookup';

ok !defined $users->get('amanda-not-b-found') => 'Nonexistent user undef';

my $members;
ok lives { $members = $users->members }       => '$users->members works';
ok $members->{'abigail'}                      => '$members contains Abigail';
is scalar keys %$members, 126                 => 'Expected number of members';

my $guests;
ok lives { $guests = $users->guests }         => '$users->guests works';

done_testing;
