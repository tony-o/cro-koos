use Koos::Model;
unit class Model::ModuleDepends does Koos::Model['module_depends'];

has @.columns = [
  module_depends_id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  module_id => {
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
  module => { :has-one, :model<Module>, :relate(module_id => 'module_id'), },
];
