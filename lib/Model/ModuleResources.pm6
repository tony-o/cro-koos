use Koos::Model;
unit class Model::ModuleResources does Koos::Model['module-resources'];

has @.columns = [
  module-resources-id => {
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
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module-id => 'module-id'), },
];
