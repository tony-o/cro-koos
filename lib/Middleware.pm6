unit module Middlware;
use Cro::HTTP::Router;
use Koos;
sub spacex(Str $x, $len) {
  ($x.chars > $len ?? $x.substr(0, $len) !! $x) ~
  ($x.chars > $len ?? '' !! (' ' x ($len - $x.chars)));
}

sub hook-db is export {
  our $koos = Koos.new;
  $koos.connect(
    driver  => 'SQLite',
    options => {
      db => {
        database => 'test.sqlite3',
      },
    },
  );

  sub server-log($req) {
    my $str = '';
    $str ~= spacex("HTTP/{$req.http-version.trim}", 9);
    $str ~= spacex($req.method.trim, 5);
    $str ~= $req.original-target;
    say $str;
  }

  Cro::HTTP::Request.^add_method('db', -> $request {
    $koos;
  }) unless Cro::HTTP::Request.^can('db');
  Cro::HTTP::Request.^add_method('model', sub ($request, $model) {
    return $koos.model($model);
  }) unless Cro::HTTP::Request.^can('model');
  before {
    server-log($_);
  }
}
