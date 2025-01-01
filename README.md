# About App::PWC

`App::PWC` is a collection of Perl utilities to assist in the operation of the
PerlWeeklyChallenge.org website.

# Synopsis

```perl
    cd /path/to/perlweeklychallenge-club/challenge-099
    pwc-review-template >~/path/to/review-challenge-099.md
``` 

# Documentation

Once this module is installed, full documentation is available via `perldoc
<command>` on your local system. Quick help is available for all commands with
the `--help` option. Documentation for all public releases is also
available on [MetaCPAN](https://metacpan.org/pod/App::PWC)


You can view the latest documentation for all commands online:
[rcon-minecraft](https://metacpan.org/pod/distribution/Net-RCON-Minecraft/bin/)

# Installation

If you simply want the latest public release, install via CPAN.

If you need to build and install from this distribution directory itself,
run the following commands:

```sh
    perl Makefile.PL
    make
    make test
    make install
```

You may need to follow your system's usual build instructions if that doesn't
work. For example, Windows users will probably want to use `gmake` instead of
`make`. Otherwise, the instructions are the same.

# Support

 - [RT, CPAN's request tracker](https://rt.cpan.org/NoAuth/Bugs.html?Queue=App-PWC): Please report bugs here.
 - [GitHub Repository](https://github.com/rjt-pl/App-PWC)

# License and Copyright

Copyright © Ryan J Thompson <<rjt@cpan.org>>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

[Perl Artistic License](http://dev.perl.org/licenses/artistic.html)
