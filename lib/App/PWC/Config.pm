use v5.38;

no warnings 'experimental';
use feature 'class';

class App::PWC::Config 0.01;

use YAML::PP;
use File::Slurper    qw< read_text write_text >;
use List::Util       qw< any all first >;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Cwd;

field $conf :param;     # The main configuration is kept here

field %canonical;       # $canonical{perl6} = 'raku'
field %extension_ok;    # $extension_ok{perl}{pl} = 1

# We get our config from Dancer::Config
ADJUST {
    $self->_validate;

    while ( my ($lang, $hash) = each %{ $conf->{lang} } ) {
        $canonical{$_}           = $lang for @{ $hash->{aliases} // [] };
        $canonical{$lang}        = $lang; # idempotent
        $extension_ok{$lang}{$_} = 1 for @{ $hash->{extensions}  // [] };
    }

}

method repo($repo) {
    croak "Repository not specified" if not defined $repo;

    $conf->{repo}{$repo} // croak "Repository `$repo' not in configuration";
}

method colors() { $self->color() } # Alias
method color($color_num = undef) {
    return @{ $conf->{color} } if not defined $color_num;

    $conf->{color}[$color_num] // croak "Color #$color_num out of range."
}

method color_iterator {
    my $idx = 0;
    my $max = @{ $conf->{color} };

    sub {
        $idx = 0 if $idx >= $max;
        $conf->{color}[$idx++]
    }
}


method lang_score($lang) {
    my $can = $self->canonical_lang($lang) // return 1;
    $conf->{lang}{$can}{score} // 1;
}


method extension_ok($lang, $ext) {
    # Everything is assumed to be permitted unless we configure it
    my $can = $self->canonical_lang($lang) // return 1;

    return 1 if not exists $conf->{lang}{$can}
             or not exists $conf->{lang}{$can}{extensions}
             or            $extension_ok{$can}{$ext}
}

method canonical_lang($lang) { $canonical{$lang} // $lang }
method blog_score            { $conf->{blog}{score} // 2 }
method dbfile()              { $conf->{dbfile} }

#
# Private
#

method _validate {
    my @err;    # Accumulated errors, displayed all at once.
    my @warn;   # Same goes for warnings

    # Validate required tokens
    for my $key (qw< repo.pwc-club repo.pwc dbfile lang.perl.score
                     lang.raku.score blog.score >) {
        my $cur = $conf;
        my $path = '';
        for my $token (split /\./, $key) {
            $path .= ($path ? '.' : '') . $token;
            if (not defined $cur->{$token}) {
                push @err, "Missing required config parameter: $key";
                last;
            }
            $cur = $cur->{$token};
        }
    }

    push @err, "dbfile ". $self->dbfile . " does not exist"
        if defined $self->dbfile and not -f $self->dbfile;

    for (qw< pwc pwc-club >) {
        push @err, "repo.$_ " . $self->repo($_) . " does not exist"
            if defined $self->repo($_) and !-d $self->repo($_);
    }

    # Display any warnings and errors we've accumulated
    cluck(join("\n   > ", 'Config warnings', @warn)) if @warn;
    carp( join("\n   > ", 'Config errors:',  @err))  if @err;
}
