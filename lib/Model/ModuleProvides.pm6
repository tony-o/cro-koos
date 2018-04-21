use Koos::Model;
unit class Model::ModuleProvides does Koos::Model['module-provides'];

has @.columns = [
  module-provides-id => {
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
  path => {
    type => 'text',
  },
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module-id => 'module-id'), },
];
