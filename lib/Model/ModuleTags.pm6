use Koos::Model;
unit class Model::ModuleTags does Koos::Model['module-tags'];

has @.columns = [
  module-tag-id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  module-id => {
    type => 'int',
  },
  tag => {
    type => 'text',
  },
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module-id => 'module-id'), },
];
