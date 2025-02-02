use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Stats 0.01;

use JSON::PP        qw< decode_json >;
use File::Slurper   qw< read_text >;
use Carp;
use DBI;

field $conf :param;

ADJUST {
    $users = App::PWC::Users->new( conf => $conf );
    Log::Log4perl::init('log4perl.conf');
    $log = Log::Log4perl->get_logger("app.pwc.stats");
    $self->_connect;
}

# Connect to SQLite database
method _connect() {
    my $dbfile = $conf->dbfile;
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');
}

# This is the basic chart generation routine, designed to be
# a relatively close match to Chart.js
method gen_chart( $name, $type, $data, $options ) {
    
}

# This generates the $data for any chart you like, based
# on an SQL query and optional filter code
method get_data( ) {
}

#
# Specific charts and helper functions here
#

method top_users( $count = 50, $mem_guest = 'member' ) {
    my $sth = $dbh->prepare(qq{
        SELECT      username, realname, ${mem_guest}_score
        FROM        Users
        LIMIT       ?
        ORDER BY    ${mem_guest}_score DESC
    });
    $sth->execute($count);

    $sth->fetchall_arrayref;
}
