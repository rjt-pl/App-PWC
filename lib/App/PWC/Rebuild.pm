use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Rebuild 0.01;

use File::Slurper   qw< read_text read_lines >;
use File::Find;
use File::Spec;
use DBI;
use Carp;
use Cwd;
use App::PWC::Users;
use Log::Log4perl;
use autodie;
no warnings         'experimental'; # Yes, we need this twice.

field $conf         :param;
field $dbh;
field $users;
field $log;

ADJUST {
    $users = App::PWC::Users->new( conf => $conf );
    Log::Log4perl::init('log4perl.conf');
    $log = Log::Log4perl->get_logger("app.pwc.rebuild");
    $self->_connect;
}

# Connect to SQLite database
method _connect() {
    my $dbfile = $conf->dbfile;

    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');
}

method drop_tables() {
    $log->info('Dropping all SQL tables');
    my $return = 1;
    for (qw<Blogs Submissions Users>) {
        my $sth = $dbh->prepare("DROP TABLE IF EXISTS $_");
        $sth->execute or do {
            $log->error("Couldn't drop $_: " . $DBI::errstr);
            $return = undef;
        }
    }

    return $return;
}

method rebuild() {
    $log->info('Rebuild started');
    $self->_create_tables;
    $self->_clear_tables;
    $self->_rebuild_users;
    $self->_rebuild_blogs_and_submissions;
}

# Create tables if needed (i.e., database does not yet exist)
method _create_tables {
    my @sql = ( 
        qq{ BEGIN TRANSACTION; },
        qq{ CREATE TABLE IF NOT EXISTS "Blogs" (
                username        TEXT NOT NULL,
                week            INTEGER NOT NULL,
                url             TEXT NOT NULL,
                score           INTEGER NOT NULL
            );
        },
        qq{ CREATE TABLE IF NOT EXISTS "Submissions" (
                username        TEXT NOT NULL,
                week            INTEGER NOT NULL,
                language        TEXT NOT NULL,
                filename        TEXT NOT NULL,
                score           INTEGER NOT NULL
            );
        },
        qq{ CREATE TABLE IF NOT EXISTS "Users" (
                username        TEXT NOT NULL UNIQUE,
                realname        TEXT NOT NULL,
                is_guest        INTEGER,
                member_score    INTEGER,
                guest_score     INTEGER,
                PRIMARY KEY("username")
            );
        },
        qq{ COMMIT; }
    );

    $log->info('Creating tables if needed');
    for (@sql) {
        $log->info("   Creating $1") if /\"([^"]+)\"/;
        my $sth = $dbh->prepare($_);
        $sth->execute or do {
            $log->error("Failed creating $1: $DBI::errstr");
            return
        }
    }

    1;
}

method _rebuild_users {
    my $members = $users->members;
    $log->info('Rebuilding users');
    for my $username (sort keys %$members) {
        my $sth = $dbh->prepare('INSERT INTO Users VALUES (?,?,?,?,?)');
        $log->debug(sprintf('Member %-24s | %s', $username, $members->{$username}));
        $sth->execute($username, $members->{$username}, 0, 0, 0);
    }

    my $guests = $users->guests;
    for my $username (sort keys %$guests) {
        my $sth = $dbh->prepare('INSERT INTO Users VALUES (?,?,?,?,?)');
        $log->debug(sprintf('Guest  %-24s | %s', $username, $guests->{$username}));
        #$sth->execute($username, $guests->{$username}, 1, 0, 0);
    }

}

method _clear_tables() {
    $log->info('Clearing database tables');
    for (qw< Users Blogs Submissions >) {
        my $sth = $dbh->prepare("DELETE FROM $_");
        $sth->execute;
    }

}

# Walk the challenge-* directories and store everything in the database
method _rebuild_blogs_and_submissions {
    my $cwd  = getcwd; # Save previous directory
    my $base = File::Spec->rel2abs( $conf->repo('pwc-club') );
    my ($submissions, $blogs) = (0,0); # Count of submissions and blogs
    my %score;  # $score{member}{ryan-thompson} == total perl, raku, blog points
                # $score{guest}{ryan-thompson} == total other points

    chdir $base;

    for my $abs_week_dir (grep { -d } glob( 'challenge-*' )) {
        chdir $abs_week_dir;
        my $rel_week_dir = File::Spec->abs2rel($abs_week_dir, getcwd);
        my ($week) = $rel_week_dir =~ /\-0*(\d+)$/;
        $log->info(sprintf("Week %3d | %s", $week, $rel_week_dir));

        my $sub_sth  = $dbh->prepare('INSERT INTO Submissions VALUES (?,?,?,?,?)');
        my $blog_sth = $dbh->prepare('INSERT INTO Blogs       VALUES (?,?,?,?)');

        my $wanted = sub {
            my $fmt = "[Wk%3d] %-20s | %10s | score:%1d | %s";
            $log->debug(sprintf("%51s / %-20s", $File::Find::dir, $_));

            # Submission
            if ($File::Find::dir =~ m!^\./ (?<user>[^/]+) / (?<lang>[^/]+) $!x) {
                my $user = $+{user};
                my $lang = $conf->canonical_lang($+{lang});
                return unless / ^ch-[123][a-z]? (\. (?<ext>.+) )?$/x;
                return unless $conf->extension_ok($lang => $+{ext});

                $log->info(sprintf($fmt,
                        $week, $user, $lang, $conf->lang_score($lang), $_));
                $submissions++;
                $sub_sth->execute($user, $week, $lang, $_, $conf->lang_score($lang));
                my $mem_guest = $conf->lang_score($lang) > 1 ? 'member' : 'guest';
                $score{$mem_guest}{$user} += $conf->lang_score($lang);

            # Blog(s)
            } elsif (m!^blog[_-]?\d?.txt$! and $File::Find::dir =~ m!\./([^/]+)$!) {
                my $username = $1;
                my @urls = read_lines($_);
                for (@urls) {
                    $log->info(sprintf($fmt,
                            $week, $username, 'blog', $conf->blog_score, $_));
                    $blog_sth->execute($1, 0+$week, $_, $conf->blog_score);
                    $score{member}{$username} += $conf->blog_score;
                }
                $blogs++;
            }
        };
        find($wanted, '.');


        chdir($base);
    }

    $log->info(sprintf('Rebuilt. %d submissions, %d blogs', $submissions, $blogs));
    $self->update_scores( %score );
    chdir $cwd;

    return 1;
}

method update_scores( %score ) {
    for my $mem_guest ( qw< member guest > ) {
        for my $user ( sort keys %{ $score{$mem_guest} } ) {
            my $sth = $dbh->prepare(qq{
                UPDATE      Users
                    SET     ${mem_guest}_score = ?
                    WHERE   username = ?
            });
            my $score = $score{$mem_guest}{$user};
            $log->info(sprintf("Total %6s score for %16s = %4d",
                        $mem_guest, $user, $score));
            $sth->execute($score, $user);
        }
    }
    $log->info('All scores updated');
}
