#!perl -T

use Test2::V0 -target => 'App::PWC::Config';

my $conf;

ok lives { $conf = CLASS->new(config_file => 'config/pwc.yaml') },
    'Constructor';

done_testing;
