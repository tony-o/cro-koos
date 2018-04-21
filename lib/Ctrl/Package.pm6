unit module Ctrl::Package;
use Cro::HTTP::Router;

our sub available('available', :$req = request) {
  CATCH { default { .say ; } }
  my %criteria;
  request-body -> %params {
    %criteria<name> = %params<name> if %params<name>;
    %criteria<auth> = %params<auth> if %params<auth>;
    %criteria<api>  = %params<api>  if %params<api>;
    # version/auth/api
    %criteria<version> = Version.new(%params<version>)
      if %params<version>;
  } if $req.method eq 'POST';
  my @mods = search-modules(%criteria.grep({ $_.key ne 'version' }).Hash);
  @mods = @mods.grep({
    my Version $v .=new( $_.version );
    $v ~~ %criteria<version> 
  }) if %criteria<version>; 
  content 'application/json', {
    meta_list => build-meta(@mods),
    results   => @mods.elems,
  };
}

sub search-modules(%criteria) {
  my $mod = request.model('Module').search(%criteria);
  my $provides = request.model('ModuleProvides');
  my @mods = $mod.all;
  @mods.push(|$provides.search({ name => %criteria<name> }).all.map({ .module }))
    if %criteria<name>;
  @mods;
}

sub build-meta(@x) {
  @x.map({ %(
    provides => %(
      $_.provides.all.map({$_.name => $_.path})
    ),
    depends => [$_.depends.search({ type => 'runtime' }).all.map(*.as-hash)],
    build_depends => [$_.depends.search({ type => 'build' }).all.map(*.as-hash)],
    test_depends => [$_.depends.search({ type => 'test' }).all.map(*.as-hash)],
    resources => [$_.resources.all.map(*.as-hash<name>)],
    tags => [$_.tags.all.map(*.as-hash<tag>)],
    authors => [$_.authors.all.map(*.as-hash<name>)],
    $_.as-hash.grep({ $_.key ne 'module_id' }).Slip,
  ) });
}

