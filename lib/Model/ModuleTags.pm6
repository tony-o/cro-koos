use Koos::Model;
unit class Model::ModuleTags does Koos::Model['module_tags'];

has @.columns = [
  module_tag_id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  module_id => {
    type => 'int',
  },
  tag => {
    type => 'text',
  },
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module_id => 'module_id'), },
];
