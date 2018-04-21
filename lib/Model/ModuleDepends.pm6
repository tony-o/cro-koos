use Koos::Model;
unit class Model::ModuleDepends does Koos::Model['module-depends'];

has @.columns = [
  module-depends-id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  module-id => {
    type => 'int',
  },
  name => {
    type => 'text',
  },
  type => {
    type => 'varchar',
    length => 16,
  },
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module-id => 'module-id'), },
];
