use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;

my $conf = App::PWC::Config->new( conf => {
        repo    => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
        dbfile  => 'pwc.sqlite',
    } );

my $data = CLASS()->new( conf => $conf );

ok(1);

done_testing;
