use Koos::Model;
unit class Model::Module does Koos::Model['module', 'Row::Module'];

has @.columns = [
  module-id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  name => {
    type => 'varchar',
    length => 128,
  },
  auth => {
    type => 'varchar',
    length => 128,
  },
  api => {
    type => 'varchar',
    length => 64,
  },
  version => {
    type => 'varchar',
    length => 64,
  },
  description => {
    type => 'text',
  },
  license => {
    type => 'text',
  },
  source-url => {
    type => 'text',
  },
];

has @.relations = [
  depends   => { :has-many, :model<ModuleDepends>,   :relate(module-id => 'module-id'), },
  tags      => { :has-many, :model<ModuleTags>,      :relate(module-id => 'module-id'), },
  provides  => { :has-many, :model<ModuleProvides>,  :relate(module-id => 'module-id'), },
  authors   => { :has-many, :model<ModuleAuthors>,   :relate(module-id => 'module-id'), },
  resources => { :has-many, :model<ModuleResources>, :relate(module-id => 'module-id'), },
];
