use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Rebuild 0.01;

use App::PWC::Users;
use File::Slurper   qw< read_text read_lines >;
use File::Find;
use File::Spec;
use Carp;
use Cwd;
use Log::Log4perl;
use JSON::PP        qw< decode_json >;
use autodie;
no warnings         'experimental'; # Yes, we need this twice.

field $conf         :param;
field $users;
field $log;
field $db;

ADJUST {
    Log::Log4perl::init('log4perl.conf');
    $db = App::PWC::DB->new( dbfile => $conf->dbfile );
    $log = Log::Log4perl->get_logger("app.pwc.rebuild");
}

method drop_tables() {
    $log->info('Dropping all SQL tables');
    for (qw<Blogs Submissions Users>) {
        $db->query("DROP TABLE IF EXISTS $_") or _db_fatal("Can't drop $_");
    }
    return 1;
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
    );

    $log->info('Creating tables if not exist');
    $db->query($_) or _db_fatal("Can't create table") for @sql;

    1;
}

method _rebuild_users {
    my ($members, $guests);
    $log->info('Rebuilding users');

    for my $group (qw< guests members >) {
        my $filename = join '', $conf->repo('pwc-club'), '/', $group, '.json';
        my $text     = read_text($filename);
        my $hash     = decode_json $text;

        croak "$filename must contain a hash" if 'HASH' ne ref $hash;

        $guests  = $hash if $group eq 'guests';
        $members = $hash if $group eq 'members';
    }

    # Look for duplicates and delete them from $guests with a warning
    my @dupes = grep { exists $members->{$_} } keys %$guests;
    if (@dupes) {
        $log->warn("There are users who are both members and guests:");
        $log->warn("   > $_") for sort @dupes;
        delete $guests->{$_} for @dupes;
    }

    my @rows = map { [ $_, $members->{$_}, 0, 0, 0 ] } sort keys %$members;
    push @rows, map { [ $_, $guests->{$_}, 1, 0, 0 ] } sort keys %$guests;

    $db->query('INSERT INTO Users VALUES (?,?,?,?,?)', @rows);

    $users = App::PWC::Users->new( conf => $conf ); # Will load from DB
}

method _clear_tables() {
    $log->info('Clearing database tables');
    $db->query("DELETE FROM $_") for qw< Users Blogs Submissions >;
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

        my (@subs, @blogs);

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
                push @subs, [$user, $week, $lang, $_, $conf->lang_score($lang)];
                my $mem_guest = $conf->lang_score($lang) > 1 ? 'member' : 'guest';
                $score{$mem_guest}{$user} += $conf->lang_score($lang);

            # Blog(s)
            } elsif (m!^blog[_-]?\d?.txt$! and $File::Find::dir =~ m!\./([^/]+)$!) {
                my $username = $1;
                my @urls = read_lines($_);
                for (@urls) {
                    $log->info(sprintf($fmt,
                            $week, $username, 'blog', $conf->blog_score, $_));
                    push @blogs, [$1, 0+$week, $_, $conf->blog_score];
                    $score{member}{$username} += $conf->blog_score;
                }
                $blogs++;
            }
        };
        find($wanted, '.');

        $log->info("Adding $submissions submissions and $blogs blogs...");
        $db->query('INSERT INTO Submissions VALUES (?,?,?,?,?)', @subs);
        $db->query('INSERT INTO Blogs       VALUES (?,?,?,?)', @blogs);

        chdir($base);
    }

    $log->info(sprintf('Rebuilt. %d submissions, %d blogs', $submissions, $blogs));
    $self->update_scores( %score );
    chdir $cwd;

    return 1;
}

method update_scores( %score ) {
    for my $which ( qw< member guest > ) {
        my @param;
        for my $user ( sort keys %{ $score{$which} } ) {
            my $score = $score{$which}{$user};
            $log->info(sprintf("Total %6s score for %16s = %4d",
                        $which, $user, $score));
            push @param, [ $score, $user ];
        }
        $db->query(qq{UPDATE Users SET ${which}_score = ? WHERE username = ? },
            @param);
    }

    $log->info('All scores updated');
}
