use v5.38;
use Test2::V0 -target => 'App::PWC::Stats';
use App::PWC::Config;

my $conf_hash = {
    repo => { 'pwc-club' => 't/sample/perlweeklychallenge-club' },
};

my $conf  = App::PWC::Config->new( conf => $conf_hash );
my $users = CLASS()->new( conf => $conf );

ok(1);

done_testing;
