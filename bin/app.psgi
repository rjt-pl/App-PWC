#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use App::PWC;

App::PWC->to_app;

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use App::PWC;
use Plack::Builder;

builder {
    enable 'Deflater';
    App::PWC->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to mount several applications on different path

use App::PWC;
use App::PWC_admin;

use Plack::Builder;

builder {
    mount '/'      => App::PWC->to_app;
    mount '/admin'      => App::PWC_admin->to_app;
}

=end comment

=cut

