#!perl

use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;

my $conf = App::PWC::Config->new( config_file => 't/sample/config/pwc.yaml' );
my $rebuild = CLASS()->new( conf => $conf );

ok $rebuild->drop_tables        => 'Dropped tables';
ok $rebuild->_create_tables     => 'Created tables';

done_testing;
