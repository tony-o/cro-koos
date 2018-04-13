#!/usr/bin/env perl6

use Cro::HTTP::Router;
use lib 'lib';
use Router;

my $application = build-router;

my Cro::Service $hello = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;
$hello.start;
react whenever signal(SIGINT) { $hello.stop; exit; }
