use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::DB 0.01;

use DBI;
use Carp;
use Log::Log4perl;
use Try::Tiny;
use List::Util qw< any all none reduce >;
use autodie;
no warnings         'experimental'; # Yes, we need this twice.

field $dbfile       :param;
field $l4p_conf     :param = 'log4perl.conf';
field $log_facility :param = 'app.pwc.db';
field $dbh          :reader;
field $log;

ADJUST {
    # Singleton pattern. These are only ever initialized once.
    state ($_log, $_dbh);

    if (not defined $_log) {
        Log::Log4perl::init('log4perl.conf');
        $log = $_log = _get_new_logger($log_facility);

        $log->info("Connecting to DB $dbfile ...");
        $dbh = $_dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '')
            or _db_fatal("Failed to open SQLite DB `$dbfile'");
        $dbh->{AutoCommit} = 0;
    } else {
        ($dbh, $log) = ($_dbh, $_log);
    }

    $SIG{__WARN__} = _db_warn($log_facility);

}


method query($sql, @param) {
    $sql =~ s/\s*$//gs;
    $log->debug("SQL> $sql");
    my @rows;

    # Ensure we have multiple rows, regardless of input
    @rows   = [ @param ] if @param > 0 and none { ref } @param; # One row
    @rows   =   @param   if @param > 0 and all { 'ARRAY' eq ref } @param;
    @rows   = (   []   ) if @rows == 0;

    $self->_db_fatal("\@param must be ARRAY refs or scalars") unless @rows;

    my @retval;

    $self->_query_atom('BEGIN TRANSACTION');
    my $row = 0;
    for (@rows) {
        $row++;
        $log->debug("  > Params: @$_") if @$_ > 0 and $row < 7;
        $log->debug("  > ... and " . (@rows-$row) . " more rows ...") if $row == 7;
        my $res = $self->_query_atom($sql, @$_);
        push @retval, 'ARRAY' eq ref $res ? @$res : $res if defined $res;
    }
    $self->_query_atom('COMMIT');

    return @retval;
}


#
# Private methods and subs
#

# Single query, only works on scalar param lists (single row only)
# Does not BEGIN TRANSACTION or COMMIT
method _query_atom($sql, @param) {
    my $sth = $dbh->prepare($sql)   or $self->_db_fatal("prepare() failed");
    my $rc  = $sth->execute(@param) or $self->_db_fatal("execute() failed");

    # Now determine if we have a SELECT result and return accordingly
    return $sth->{NUM_OF_FIELDS} > 0 ? $sth->fetchall_arrayref : $rc;
}


# Use caller() to get a pretty-printed summary for use in logging
# Also trims $msg to remove line number from DB.pm itself
sub _caller_msg($msg) {
    # Grab the bits we need from the callstack
    my ($dbpkg, undef, $dbline)     = caller(1); # DB.pm line number
    my ($pkg, undef, $line, $dbsub) = caller(2); # caller line, DB.pm sub
    my (undef, undef, undef, $sub)  = caller(3); # caller sub

    $msg   =~ s! at .+?lib[/\\]App[/\\]PWC[/\\]DB.pm line (\d+)\.\n$!!;
    $sub   =~ s/^.*:://g;
    $dbsub =~ s/^.*:://g;
    $msg   =~ s/^DBD::[^:]+::db/DB/;
    
    "$msg at $pkg\::$sub() line $line via $dbpkg\::$dbsub() line $dbline.";
}

# This returns a NEW logger object every time
sub _get_new_logger($facility) { Log::Log4perl->get_logger($facility) }

# Database warnings are trapped and logged here.
# This comes from $SIG{__WARN__} so we need to make a new logger here.
# This returns a CODE ref for use with $SIG{__WARN__}, which is
# the only way we can get the correct logging facility.
sub _db_warn($facility) {
    sub { _get_new_logger($facility)->warn(_caller_msg($_)) for @_ }
}

# Fatal database operation. Logs $DBI::errstr, so no need to include that.
method _db_fatal($msg) { $log->logdie(_caller_msg($msg)) }
