use v5.38;
use Test2::V0 -target => 'App::PWC::Rebuild';
use App::PWC::Config;
use lib qw< t/lib >;
use Local::TestRoutines;

use File::Temp qw< tempfile >;

my $dbfile = t_dbfile;

my $conf = App::PWC::Config->new( conf => t_config );
my $rebuild = CLASS()->new( conf => $conf );

ok $rebuild->_create_tables     => 'Created tables';
ok $rebuild->   drop_tables     => 'Dropped tables';

unlink $dbfile;
done_testing;
