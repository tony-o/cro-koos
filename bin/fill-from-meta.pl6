#!/usr/bin/env perl6
use lib 'lib';
use Koos;
use JSON::Fast;
require App::ecogen;

my $koos = Koos.new;
$koos.connect(driver => 'SQLite', options => { db => { database => 'test.sqlite3', }, }, );

my $mod-m = $koos.model('Module');

multi sub MAIN('update', Bool :$skip-download = False) {
  my $local-uri = $*CWD.child("ecosystems").absolute andthen *.IO.mkdir;
  if !$skip-download {
    my $proc = run('ecogen', '--/remote', '--local', qq|--local-uri=$local-uri|, 'update', 'p6c','cpan');
    die "Failed to update ecosystem data" unless $proc.so;
  }
  process($local-uri);
}

multi sub MAIN(Any:D :$path) {
  die "{$path.IO.absolute} not found"
    unless $path.IO ~~ :e;

  process($path.IO); 

}

multi sub process(IO() $path where { $_ ~~ :d }) {
  for $path.dir -> $x {
    next if $x ~~ :f && $x.basename !~~ /'.json'$$/;
    process $x;
  }
}

multi sub process(IO() $path where { $_ ~~ :f }) {
  say "==> Processing {$path.relative}";
  my $data = from-json $path.slurp;
  if $data ~~ Array {
    for @($data).grep(*.defined) -> %obj {
      process %obj;
    }
  } else {
    process($data.Hash);
  }

}

multi sub process(%data) {
  # check for existence
  my ($version, $api, $auth) = (
    %data<version>//%data<ver>,
    %data<api>//Any,
    %data<auth>.defined || (%data<author>.defined && %data<author> ~~ Str) ?? (%data<auth>//%data<author>) !! Any,
  );
  $auth = $auth[0] if $auth ~~ Array;
  my $found = $mod-m.search({
    name    => %data<name>,
    version => $version,
    ( $api.defined ?? (api => $api) !! ()),
    ( $auth.defined ?? (auth => $auth) !! ()),
  }).count;
  return if $found;


  "==> adding entry for {%data<name>}:ver<{$version}>:auth<{$auth//''}>:api<{$api//''}>".say;
  my $module = $mod-m.new-row({
    name => %data<name>,
    auth => $auth,
    ($api.defined ?? (api => $api) !! ()),
    version => $version,
    description => %data<description>,
    license => %data<license> ~~ Array ?? %data<license>.join(' and ') !! %data<license>,
    source-url => %data<source-url>//%data<support><source>//Any,
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
  create-depends $module, @(%data<depends>).grep(*.defined), :type<runtime>;
  
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
      type      => $type,
      module-id => $module.module-id,
    }).update;
  }
}
