use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC::Config 0.01;

use YAML::PP;
use File::Slurper qw< read_text write_text >;
use List::Util qw< any all first >;
use Carp;
use Cwd;

field $config_file :param :reader;
field %conf;            # Actual config data here
field %canonical;       # $canonical{perl6} = 'raku'
field %extension_ok;    # $extension_ok{perl}{pl} = 1

# Automatically read config file on object creation
ADJUST {
    croak "Config `" . $config_file . "' not found." if !-f $config_file;

    my $ypp = YAML::PP->new;
    my @docs = $ypp->load_file($config_file);
    croak "Config file can only have one document (`---')" if @docs != 1;

    %conf = %{ $docs[0] };
    $self->_validate;

    while ( my ($lang, $hash) = each %{ $conf{lang} } ) {
        $canonical{$_}           = $lang for @{ $hash->{aliases} // [] };
        $canonical{$lang}        = $lang; # idempotent
        $extension_ok{$lang}{$_} = 1 for @{ $hash->{extensions}  // [] };
    }

}

method repo($repo) {
    croak "Repository not specified" if not defined $repo;

    $conf{repo}{$repo} // croak "Repository `$repo' not in configuration";
}

method colors() { $self->color() } # Alias
method color($color_num = undef) {
    return @{ $conf{color} } if not defined $color_num;

    $conf{color}[$color_num] // croak "Color #$color_num out of range."
}

method color_iterator {
    my $idx = 0;
    my $max = @{ $conf{color} };

    sub {
        $idx = 0 if $idx >= $max;
        $conf{color}[$idx++]
    }
}


method lang_score($lang) {
    my $can = $self->canonical_lang($lang) // return 1;
    $conf{lang}{$can}{score} // 1;
}


method extension_ok($lang, $ext) {
    # Everything is assumed to be permitted unless we configure it
    my $can = $self->canonical_lang($lang) // return 1;

    return 1 if not exists $conf{lang}{$can}
             or not exists $conf{lang}{$can}{extensions}
             or            $extension_ok{$can}{$ext}
}

method canonical_lang($lang) { $canonical{$lang} // $lang }
method blog_score            { $conf{blog}{score} }
method dbfile()              { $conf{dbfile} }
method rebuild_log           { $conf{log}{rebuild_log} }
method num_logs              { $conf{log}{num_logs} }
method log_strftime          { $conf{log}{strftime} }
method console_strftime      { $conf{log}{console_strftime} }
method log_level             { $conf{log}{level} }
method console_level         { $conf{log}{console_level} }
method gzip_logs             { $conf{log}{gzip_logs} }

#
# Private
#

method _validate {
    # TODO
}

