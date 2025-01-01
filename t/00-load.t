#!perl -T
use v5.38;
use strict;
use warnings;
use Test2::V0;

ok lives { use App::PWC };

diag( "Testing App::PWC $App::PWC::VERSION, Perl $], $^X" );

done_testing;
