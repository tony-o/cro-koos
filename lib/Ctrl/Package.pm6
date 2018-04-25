unit module Ctrl::Package;
use Text::Levenshtein::Damerau;
use Cro::HTTP::Router;

our sub candidates('candidates', :$req = request) {
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
    meta-list => clean-meta(build-meta(@mods, $rname)),
    results   => @mods.elems,
  };
}

our sub dependencies('dependencies', :$req = request) {
  request-body -> %params {
    my %criteria;
    %criteria<name>    = %params<name>;
    %criteria<auth>    = %params<auth>    if %params<auth>;
    %criteria<api>     = %params<api>     if %params<api>;
    %criteria<version> = %params<version> if %params<version>;
    my $mod = $req.model('Module').search(%criteria).first;
    return content 'application/json', {
      success => 0,
      message => 'Module not found',
    } unless $mod;
    my @tier = build-tiers($mod);
    @tier = clean-meta @tier;
    content 'application/json', {
      success     => 1,
      build-tiers => @tier,
    };
  }
}

sub build-tiers($mod, :$depth = 10) {
  return if $depth <= 0;
  my @deps;
  my @get-deps = $mod;
  my @swap-deps;
  my %got-deps = :nap, :Test,;
  my $m-rs = $mod.dbo.model('Module');
  my @errors;
  repeat { # my brain isn't working, this is a hack.
    @swap-deps = ();
    for @get-deps -> $dep {
      next if %got-deps{$dep.name};
      @deps.push($dep);
      %got-deps{$dep.name} = True;
      for @($dep.depends.all).grep(*.defined && *.^can('name')) -> $x {
        my $mod2 = $m-rs.search(%( name => $x.name, )).first;
        @errors.push($x.name), next unless $mod2;
        @swap-deps.push($mod2) unless %got-deps{$mod2.name};
      }
    }
    @get-deps = @swap-deps;
  } while @get-deps.elems;
  @deps = build-meta( @deps, $mod.name );
  @deps;
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

sub clean-meta(@x) {
  for @x -> $meta is rw {
    $meta<__internal__>:delete;
    for [qw<depends build-depends test-depends>] -> $dep {
      $meta{$dep} = $meta{$dep}.map({
        $_<name>
      });
    }
  }
  @x;
}
