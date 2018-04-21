use Koos::Model;
unit class Model::ModuleProvides does Koos::Model['module_provides'];

has @.columns = [
  module_provides_id => {
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
  path => {
    type => 'text',
  },
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module_id => 'module_id'), },
];
