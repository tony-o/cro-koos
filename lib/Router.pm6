unit module Router;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use YAML::Parser::LibYAML;
use Middleware;

sub build-router is export {
  my %routes = yaml-parse('routes.yaml');
  my %map    = (
    get => &get,
  );
  route {
    hook_db;
    for %routes.keys -> $method {
      for @(%routes{$method}) -> $c {
        say "Loading $c";
        try {
          CATCH { default { warn "Failed to load {$c.split('::&')[0]}\n"~$_.Str } };
          my ($ct, $me) = $c.split('::&');
          $me = "&{$me}";
          require ::($ct.Str);
          %map{$method}.( 
            ::("{$ct.Str}::{$me.Str}")
          );
        };
      }
    }
  };
}
