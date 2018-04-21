unit module Router;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use YAML::Parser::LibYAML;
use Middleware;

sub build-router is export {
  my %routes = yaml-parse('routes.yaml');
  my $max    = 4;

  my @route;
  for %routes.keys -> $method {
    for @(%routes{$method}) -> $c {
      say "Loading {$method}{' ' x 1 + $max - $method.chars}\-> $c";
      try {
        CATCH { default { warn "Failed to load {$c.split('::&')[0]}\n"~$_.Str } };
        my ($ct, $me) = $c.split('::&');
        require ::($ct.Str);
        @route.push($method => ::($c.Str));
      };
    }
  }
    
  route {
    hook-db;
    for @route -> $r {
      given $r.key {
        when 'post' {
          post $r.value;
        }
        when 'get' {
          get $r.value;
        }
      };
    }
  };
}
