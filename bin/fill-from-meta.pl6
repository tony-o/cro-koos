#!/usr/bin/env perl6
use lib 'lib';
use Koos;
use JSON::Fast;

my $koos = Koos.new;
$koos.connect(driver => 'SQLite', options => { db => { database => 'test.sqlite3', }, }, );

my $mod-m = $koos.model('Module');

sub MAIN(Any:D :$path) {
  die "{$path.IO.absolute} not found"
    unless $path.IO ~~ :e;

  process($path.IO); 

}

multi sub process(IO $path where { $_ ~~ :d }) {
  for $path.dir -> $x {
    next if $x ~~ :f && $x.basename ne 'META6.json';
    process $x;
  }
}

multi sub process(IO $path where { $_ ~~ :f }) {
  say "==> Processing {$path.relative}";
  my %data = from-json $path.slurp;

  # check for existence
  my ($version, $api, $auth) = (
    %data<version>//%data<ver>,
    %data<api>//Any,
    %data<auth>.defined || (%data<author>.defined && %data<author> ~~ Str) ?? (%data<auth>//%data<author>) !! Any,
  );
  my $found = $mod-m.search({
    name    => %data<name>,
    version => $version,
    ( $api.defined ?? (api => $api) !! ()),
    ( $auth.defined ?? (auth => $auth) !! ()),
  }).count;
  return if $found;


  "==> adding entry for {%data<name>}:ver<{$version}>:auth<{$auth}>:api<{$api//''}>".say;
  my $module = $mod-m.new-row({
    name => %data<name>,
    auth => $auth,
    ($api.defined ?? (api => $api) !! ()),
    version => $version,
    description => %data<description>,
    license => %data<license>,
    source-url => %data<source-url>,
  });
  $module.update;
  if %data<authors>.defined && (%data<authors> ~~ Array || %data<auth>.defined) {
    my @authors = %data<authors>.flat; 
    for @authors -> $author {
      $module.authors.new-row({
        module-id => $module.module-id,
        name      => $author,
      }).update;
    }
  }

  create-depends $module, @(%data<test-depends>).grep(*.defined), :type<test>;
  create-depends $module, @(%data<build-depends>).grep(*.defined), :type<build>;
  create-depends $module, @(%data<depends>).grep(*.defined);
  
  for %(%data<provides>) -> $provide {
    $module.provides.new-row({
      module-id => $module.module-id,
      name      => $provide.key,
      path      => $provide.value,
    }).update;
  }
  for @(%data<resources>).grep(*.defined) -> $r {
    $module.resources.new-row({
      module-id => $module.module-id,
      name      => $r,
    }).update;
  }
  for @(%data<tags>).grep(*.defined) -> $r {
    $module.tags.new-row({
      module-id => $module.module-id,
      tag       => $r,
    }).update;
  }
}

sub create-depends($module, @on, :$type = 'runtime') {
  for @on -> $dep {
    $module.depends.new-row({
      name      => $dep,
      type      => 'test',
      module-id => $module.module-id,
    }).update;
  }
}
