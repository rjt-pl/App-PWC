use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Stats 0.01;

use JSON::PP        qw< decode_json >;
use File::Slurper   qw< read_text >;
use Carp;

field $conf :param;

ADJUST {

}

