use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;

my $conf_hash = {
    repo   => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
    dbfile => 'pwc.sqlite',
    blog   => { score => 2 },
};

my $conf = App::PWC::Config->new( conf => $conf_hash );
my $data = CLASS()->new( conf => $conf );

ok $data->rebuild, 'Rebuild successful';

done_testing;
