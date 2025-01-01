use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Users 0.01;

use JSON::PP        qw< decode_json >;
use File::Slurper   qw< read_text >;
use Carp;

field $conf        :param;
field %guests      :reader;
field %members     :reader;

# Read the JSON files when the object is created
ADJUST {

    for my $group (qw< guests members >) {
        my $filename = join '', $conf->repo('pwc-club'), '/', $group, '.json';
        my $text     = read_text($filename);
        my $hash     = decode_json $text;

        croak "$filename must contain a hash" if 'HASH' ne ref $hash;

        %guests  = %$hash if $group eq 'guests';
        %members = %$hash if $group eq 'members';
    }

}

method realname($user) { $members{$user} // $guests{$user} }
