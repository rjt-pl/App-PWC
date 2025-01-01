#!perl -T

use Test2::V0 -target => 'App::PWC::Stats';
use App::PWC::Config;

my $conf = App::PWC::Config->new( config_file => 'config/pwc.yaml' );

my $users = CLASS()->new( conf => $conf );

ok(1);

done_testing;
