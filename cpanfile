requires "Dancer2" => "1.1.2";

requires   "YAML"                    => "0";
recommends "URL::Encode::XS"         => "0";
recommends "CGI::Deurl::XS"          => "0";
recommends "CBOR::XS"                => "0";
recommends "YAML::XS"                => "0";
recommends "Class::XSAccessor"       => "0";
recommends "Crypt::URandom"          => "0";
recommends "HTTP::XSCookies"         => "0";
recommends "HTTP::XSHeaders"         => "0";
recommends "Math::Random::ISAAC::XS" => "0";
recommends "MooX::TypeTiny"          => "0";
recommends "Type::Tiny::XS"          => "0";
recommends "Unicode::UTF8"           => "0";

requires   "Compress::Zlib"          => "0";
requires   "Logfile::Rotate"         => "1.04";
requires   "Log::Log4perl"           => "0";
requires   "DBI"                     => "1.644";
requires   "File::Slurper"           => 0,
requires   "YAML::PP"                => "0.38.0";

feature 'accelerate', 'Accelerate Dancer2 app performance with XS modules' => sub {
    requires "URL::Encode::XS"         => "0";
    requires "CGI::Deurl::XS"          => "0";
    requires "YAML::XS"                => "0";
    requires "Class::XSAccessor"       => "0";
    requires "Cpanel::JSON::XS"        => "0";
    requires "Crypt::URandom"          => "0";
    requires "HTTP::XSCookies"         => "0";
    requires "HTTP::XSHeaders"         => "0";
    requires "Math::Random::ISAAC::XS" => "0";
    requires "MooX::TypeTiny"          => "0";
    requires "Type::Tiny::XS"          => "0";
    requires "Unicode::UTF8"           => "0";
};

on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
    requires "Test2::V0"             => "0";
};

# vim: filetype=perl
