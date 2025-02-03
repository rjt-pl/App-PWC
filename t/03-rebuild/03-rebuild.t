use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;
use lib qw< t/lib >;
use Local::TestRoutines;
use File::Copy;

t_db_run_on_copy {
    my $conf = App::PWC::Config->new( conf => t_config( dbfile => $_[0] ) );
    my $data = CLASS()->new( conf => $conf );
    ok $data->rebuild, 'Rebuild successful';
};

done_testing;
