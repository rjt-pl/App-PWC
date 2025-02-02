use v5.38;
use Test2::V0 -target => 'App::PWC::DB';

my %param = ( dbfile => 't/sample/read_tests.sqlite' );

my $conf;
ok lives { $conf = CLASS->new( %param ) } => 'Constructor';

my $conf2 = CLASS->new( %param );

# Singleton is a singleton check
is $conf->dbh, $conf2->dbh => '$dbh objects share the same reference';

ok dies { $conf2 = CLASS->new } => 'Missing required params';

done_testing;
