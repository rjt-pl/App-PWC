use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;

my $conf_hash = {
    repo   => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
    dbfile => 'pwc.sqlite',
};

my $conf = App::PWC::Config->new( conf => $conf_hash );
my $rebuild = CLASS()->new( conf => $conf );

ok $rebuild->drop_tables        => 'Dropped tables';
ok $rebuild->_create_tables     => 'Created tables';

done_testing;
