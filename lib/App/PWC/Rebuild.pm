use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Rebuild 0.01;

use File::Slurper   qw< read_text read_lines >;
use File::Find;
use File::Spec;
use POSIX           qw< strftime >;
use DBI;
use Carp;
use Cwd;
use App::PWC::Users;
use Logfile::Rotate;
use autodie;

field $conf :param;
field $dbh;
field $users;
field $logger;

# Connect to SQLite database
ADJUST {
    $logger = $self->_generate_logger;
    $self->_connect;
    $users = App::PWC::Users->new( conf => $conf );
}

method _log_rotate() {
    return unless -f $conf->rebuild_log;

    my $lrot = Logfile::Rotate->new(
        File    => $conf->rebuild_log,
        Count   => $conf->num_logs,
        Gzip    => 'lib',
        Flock   => 'yes',
    );

    $lrot->rotate;
}

# Simple custom logger
method _generate_logger {
    $self->_log_rotate;
    open my $fh, '>', $conf->rebuild_log;

    my @levels =  qw< emerg alert crit error warn notice info debug >;
    my %level; while (my ($k, $v) = each @levels) { $level{$v} = $k };
    my @color = map { "\e[${_}m" } qw< 1;33;41 1;33;40 1;37;41 1;31;40
                                       0;33    1;36    0;36    0;37 >;

    sub {
        my ($level, @msg) = @_;

        my $sub = '';
        # Trundle back through a few stack frames until we find a
        # non-anonymous function.
        for my $frame (1..3) {
            my ($pkg, undef, undef, $full_sub) = caller($frame);
            $sub = $full_sub =~ s/^.+:://r;
            last if $sub !~ /^__ANON__$/;
        }
        $sub //= '__ANON__';

        my $lnum = $level{$level} // 0;
        my $log_date = strftime( $conf->log_strftime, localtime );
        if ($lnum <= $level{$conf->console_level}) {
            my $cfh = $lnum <= $level{warn} ? \*STDERR : \*STDOUT;
            printf $cfh "$color[$lnum]%s [%6s.%-6s] %s: %s\e[k\e[0m\n",
                strftime ( $conf->console_strftime, localtime ),
                $$, $level, $sub, join ' ', @msg;
        }

        if ($lnum <= $level{ $conf->log_level }) {
            printf $fh "%s [%6s] %s\n",
                strftime( $conf->log_strftime, localtime ),
                $level, join ' ', @msg;
        }
    };
}

method _connect() {
    my $dbfile = $conf->dbfile;
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');
}

method drop_tables() {
    $logger->(notice => 'Dropping all SQL tables');
    my $return = 1;
    for (qw<Blogs Submissions Users>) {
        my $sth = $dbh->prepare("DROP TABLE IF EXISTS $_");
        $sth->execute or do {
            $logger->(error => "Couldn't drop $_: " . $DBI::errstr);
            $return = undef;
        }
    }

    return $return;
}

method rebuild() {
    $logger->(notice => 'Rebuild started');
    $self->_create_tables;
    $self->_clear_tables;
    $self->_rebuild_users;
    $self->_rebuild_blogs_and_submissions;
}

# Create tables if needed (i.e., database does not yet exist)
method _create_tables {
    my @sql = ( qq{ BEGIN TRANSACTION; },
    qq{
        CREATE TABLE IF NOT EXISTS "Blogs" (
            username        TEXT NOT NULL,
            week            INTEGER NOT NULL,
            url             TEXT NOT NULL,
            score           INTEGER NOT NULL
        );
    }, qq{
        CREATE TABLE IF NOT EXISTS "Submissions" (
            username        TEXT NOT NULL,
            week            INTEGER NOT NULL,
            language        TEXT NOT NULL,
            filename        TEXT NOT NULL,
            score           INTEGER NOT NULL
        );
    }, qq{
        CREATE TABLE IF NOT EXISTS "Users" (
            username        TEXT NOT NULL UNIQUE,
            realname        TEXT NOT NULL,
            is_guest        INTEGER,
            PRIMARY KEY("username")
        );
    }, qq{ COMMIT; });

    $logger->(notice => 'Creating tables if needed');
    for (@sql) {
        $logger->(notice => "   Creating $1") if /\"([^"]+)\"/;
        my $sth = $dbh->prepare($_);
        $sth->execute or do {
            $logger->(error => "Failed creating $1: $DBI::errstr");
            return
        }
    }
    1;
}

method _rebuild_users {
    my %members = $users->members;
    $logger->(notice => 'Rebuilding users');
    for my $username (sort keys %members) {
        my $sth = $dbh->prepare('INSERT INTO Users VALUES (?,?,?)');
        $logger->(debug => sprintf('Member %-24s | %s', $username, $members{$username}));
        $sth->execute($username, $members{$username}, 0);
    }

    my %guests = $users->guests;
    for my $username (sort keys %guests) {
        my $sth = $dbh->prepare('INSERT INTO Users VALUES (?,?,?)');
        $logger->(debug => sprintf('Guest  %-24s | %s', $username, $guests{$username}));
        #$sth->execute($username, $guests{$username}, 1);
    }
}

method _clear_tables() {
    $logger->(notice => 'Clearing database tables');
    for (qw< Users Blogs Submissions >) {
        my $sth = $dbh->prepare("DELETE FROM $_");
        $sth->execute;
    }
}

# Walk the challenge-* directories and store everything in the database
method _rebuild_blogs_and_submissions {
    my $cwd = getcwd; # Save previous directory

    my $base = File::Spec->rel2abs( $conf->repo('pwc-club') );
    my ($submissions, $blogs) = (0,0);
    chdir $base;
    for my $abs_week_dir (grep { -d } glob( 'challenge-*' )) {
        next if $abs_week_dir !~ /301/;
        chdir $abs_week_dir;
        my $rel_week_dir = File::Spec->abs2rel($abs_week_dir, getcwd);
        my ($week) = $rel_week_dir =~ /\-0*(\d+)$/;
        $logger->(info => sprintf("Week %3d | %s", $week, $rel_week_dir));

        my $sub_sth  = $dbh->prepare('INSERT INTO Submissions VALUES (?,?,?,?,?)');
        my $blog_sth = $dbh->prepare('INSERT INTO Blogs       VALUES (?,?,?,?)');

        # Anonymous sub to eliminate closure warnings
        my $wanted = sub {
            my $fmt = "[Wk%3d] %-20s | %10s | score:%1d | %s";
            $logger->(debug => sprintf("%51s / %-20s", $File::Find::dir, $_));
            if ($File::Find::dir =~ m!^\./ (?<user>[^/]+) / (?<lang>[^/]+) $!x) {
                my $user = $+{user};
                my $lang = $conf->canonical_lang($+{lang});
                return unless / ^ch-[123][a-z]? (\. (?<ext>.+) )?$/x;
                return unless $conf->extension_ok($lang => $+{ext});

                $logger->(info => sprintf($fmt,
                    $week, $user, $lang, $conf->lang_score($lang), $_));
                $submissions++;
                $sub_sth->execute($user, $week, $lang, $_, $conf->lang_score($lang));

            } elsif (m!^blog[_-]?\d?.txt$! and $File::Find::dir =~ m!\./([^/]+)$!) {
                my @urls = read_lines($_);
                $logger->(info => sprintf($fmt,
                    $week, $1, 'blog', $conf->blog_score, $_)) for @urls;
                $blog_sth->execute($1, 0+$week, $_, $conf->blog_score) for @urls;
                $blogs++;
            }
        };

        find($wanted, '.');
        chdir($base);
    }
    $logger->(notice => sprintf('Rebuild finished. %d submissions, %d blogs',
            $submissions, $blogs));
    chdir $cwd;

    return 1;
}
