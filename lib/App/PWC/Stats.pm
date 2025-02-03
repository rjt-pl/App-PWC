use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Stats 0.01;

use JSON::PP        qw< decode_json >;
use File::Slurper   qw< read_text >;
use Log::Log4perl;
use App::PWC::Users;
use Carp;
use DBI;

field $conf         :param;
field $users;
field $log;
field $db;

ADJUST {
    Log::Log4perl::init('log4perl.conf');
    $users = App::PWC::Users->new( conf => $conf );
    $log   = Log::Log4perl->get_logger("app.pwc.stats");
    $db    = App::PWC::DB->new( dbfile => $conf->dbfile );
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
    croak "\$mem_guest not members or guest" if $mem_guest !~ /^(member|guest)$/;
    my $users = $users->users;

    my @top_count = sort {
        ($mem_guest eq 'guest' ? $b->guest_score : $b->member_score)
            <=>
        ($mem_guest eq 'guest' ? $a->guest_score : $a->member_score)
            ||
        $a->username cmp $b->username
    } keys %$users;

    @top_count[0..$count-1];
}
