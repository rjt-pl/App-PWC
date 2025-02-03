use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;
use lib qw< t/lib >;
use Local::TestRoutines;

my $conf = App::PWC::Config->new( conf => t_config );
my $data = CLASS()->new( conf => $conf );

ok(1);

done_testing;
