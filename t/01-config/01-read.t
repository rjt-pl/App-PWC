use v5.38;
use Test2::V0 -target => 'App::PWC::Config';

my $conf;

ok lives { $conf = CLASS->new( conf => { } ) },
    'Constructor';

done_testing;
