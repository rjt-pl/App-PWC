use v5.38;
use Test2::V0 -target => 'App::PWC::DB';
use List::Util qw< any >;

# Stub application config
my %param = ( dbfile => 't/sample/read_tests.sqlite' );

my $db = CLASS->new( %param );

my $rows = $db->query('SELECT * FROM Users');
is 'ARRAY', ref($rows), 'Got an ARRAY ref';

my @rows = @$rows;
ok @rows > 5 => 'Users has more than 5 rows';

ok(any(sub { $_->[0] eq 'abigail' }, @rows) => 'Expected user exists');

$rows = $db->query("SELECT * FROM Users WHERE username = ?", 'colin-crain');
is $rows->[0][1], 'Colin Crain' => 'Query with parameter';

done_testing;
