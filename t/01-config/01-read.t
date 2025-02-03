use v5.38;
use Test2::V0 -target => 'App::PWC::Config';
use lib qw< t/lib >;
use Local::TestRoutines;

ok lives { CLASS->new( conf => t_config() ) } => 'Constructor';

done_testing;
