use v5.38;
use feature 'class';
no warnings 'experimental';

class App::PWC 0.1;
use Dancer2;

get '/' => sub {
    info "Requested root";  
    template 'index' => { 'title' => 'App::PWC' };
};

true;
