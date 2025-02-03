use v5.38;
use feature 'class';
no warnings 'experimental';


#
# User -- Simple container class
#
class App::PWC::User 0.01;

field $realname     :param :reader;
field $username     :param :reader;
field $is_guest     :param :reader;
field $member_score :param :reader;
field $guest_score  :param :reader;


#
# Users -- Collection of User objects
#
class App::PWC::Users 0.01;

use App::PWC::DB;
use Carp;

field $conf         :param;
field $db;
field $users        :reader; # All users
field $guests       :reader; # Convenience hashes
field $members      :reader; #      "         "

# Read the JSON files when the object is created
ADJUST {
    $db = App::PWC::DB->new( dbfile => $conf->dbfile );
    $self->reload;
}

method get($username, $clauses = {}) {
    croak "\$clauses must be HASH ref. Got " . ref($clauses)
        unless 'HASH' eq ref $clauses;
    croak "\$clauses is unsupported" if keys %$clauses > 0;

    $users->{$username}
}

method reload() {
    my @cols = qw< username realname is_guest member_score guest_score >;

    for my $row ($db->query('SELECT * FROM Users')) {
        my $username = $row->[0];
        my %user_hash = map { $cols[$_] => $row->[$_] } 0..$#cols;
        my $user = $users->{$username}   = App::PWC::User->new(%user_hash);

        # Housekeeping for convenience
        $members->{$username} = $user if !$user->is_guest;
        $guests->{$username}  = $user if  $user->is_guest;
    }
}
