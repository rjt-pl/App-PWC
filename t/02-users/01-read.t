use v5.38;
use Test2::V0 -target => 'App::PWC::Users';
use App::PWC::Config;
use lib qw< t/lib >;
use Local::TestRoutines;

my $conf  = App::PWC::Config->new( conf => t_config );
my $users = CLASS()->new(          conf => $conf    );

my $user = $users->get('ash');
is ref($users->get('ash')), 'App::PWC::User'  => 'User ash exists';
is      $user->realname,    'Andrew Shitov'   => 'Real name lookup';

ok !defined $users->get('amanda-not-b-found') => 'Nonexistent user undef';

my $members;
ok lives { $members = $users->members }       => '$users->members works';
ok $members->{'abigail'}                      => '$members contains Abigail';
is scalar keys %$members, 320                 => 'Expected number of members';

my $guests;
ok lives { $guests = $users->guests }         => '$users->guests works';

done_testing;
