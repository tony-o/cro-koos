unit module Middlware;
use Cro::HTTP::Router;
use Koos;

sub hook_db is export {
  my Koos $koos .=new;
  $koos.connect(
    driver  => 'SQLite',
    options => {
      db => {
        database => 'test.sqlite3',
      },
    },
  );
  before {
    $_.^add_method('db', -> $request {
      $koos;
    }) unless $_.^can('db');
    $_.^add_method('model', -> $request, $model {
      $koos.model($model);
    }) unless $_.^can('model');
  };
}
