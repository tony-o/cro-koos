unit module Ctrl::Package;
use Text::Levenshtein::Damerau;
use Cro::HTTP::Router;

our sub available('candidates', :$req = request) {
  CATCH { default { .say ; } }
  my %criteria;
  my $rname = '';
  request-body -> %params {
    %criteria<name> = { like => '%'~%params<name>~'%' } if %params<name>;
    %criteria<auth> = %params<auth> if %params<auth>;
    # version/auth/api
    %criteria<api>     = Version.new(%params<api>)
      if %params<api>;
    %criteria<version> = Version.new(%params<version>)
      if %params<version>;
    $rname = %params<name> if %params<sort>;
  } if $req.method eq 'POST';
  my @mods = search-modules(%criteria.grep({ $_.key !~~ any('version', 'api') }).Hash);
  @mods = @mods.unique(:with(-> $a, $b {
       $a.name eqv $b.name
    && $a.version eqv $b.version
    && $a.auth eqv $b.auth
    && Version.new($a.api//'') ~~ Version.new($b.api//'');
  }));
  @mods = @mods.grep({
    my Version $v .=new( $_.version );
    $v ~~ %criteria<version> 
  }) if %criteria<version>; 
  @mods = @mods.grep({
    my Version $v .=new( $_.api // '' );
    $v ~~ %criteria<api>
  }) if %criteria<api>;
  content 'application/json', {
    meta-list => build-meta(@mods, $rname),
    results   => @mods.elems,
  };
}

sub search-modules(%criteria) {
  my $mod = request.model('Module').search(%criteria);
  my $provides = request.model('ModuleProvides');
  my @mods = $mod.all;
  @mods.push(|$provides.search({ name => %criteria<name> }).all.grep({
    ((%criteria<auth>.defined && %criteria<auth> eq .module.auth) || !%criteria<auth>.defined)
    &&
    ((%criteria<api>.defined && Version.new(%criteria<api>//'') ~~ %criteria<api>) || !%criteria<api>.defined)
  }).map({ .module })) if %criteria<name>;
  @mods;
}

sub build-meta(@x, $name = '') {
  my @r = @x.map({ 
    my $dld-match = $_.name.lc.index($name.lc) ?? $_.name !! $_.provides.all.map({.name}).grep(*.lc.match($name.lc)).first;
    %(
      provides => %(
        $_.provides.all.map({$_.name => $_.path})
      ),
      depends => [$_.depends.search({ type => 'runtime' }).all.map(*.as-hash)],
      build-depends => [$_.depends.search({ type => 'build' }).all.map(*.as-hash)],
      test-depends => [$_.depends.search({ type => 'test' }).all.map(*.as-hash)],
      resources => [$_.resources.all.map(*.as-hash<name>)],
      tags => [$_.tags.all.map(*.as-hash<tag>)],
      authors => [$_.authors.all.map(*.as-hash<name>)],
      $_.as-hash.grep({ $_.key ne 'module-id' }).Slip,
      __internal__ => {
        match-score => $name ne '' && $dld-match ?? dld($name.lc, $dld-match.lc) / $name.chars !! 0,
      },
    )
  });
  @r.=sort({
    $^a<__internal__><match-score> cmp $^b<__internal__><match-score> 
  }) if $name ne '';
  @r;
}

