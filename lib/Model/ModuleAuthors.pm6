use Koos::Model;
unit class Model::ModuleAuthors does Koos::Model['module_authors'];

has @.columns = [
  module_author_id => {
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
];

has @.relations = [
  module => { :has-one, :model<Module>, :relate(module_id => 'module_id'), },
];
