#!perl

use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;

my $conf = App::PWC::Config->new( config_file => 'config/pwc.yaml' );
my $data = CLASS()->new( conf => $conf );

ok(1);

done_testing;
