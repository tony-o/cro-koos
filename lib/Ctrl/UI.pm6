unit module Ctrl::UI;
use Cro::HTTP::Router;

our sub main(:$req = request) {
  CATCH { default { .say ; } }
  static 'static/index.htm';
}

our sub try-static(*@path, :$req = request) {
  static 'static/', @path;
}
