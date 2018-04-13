use Koos::Model;
unit class Model::Data does Koos::Model['data'];

has @.columns = [
  id => {
    is-primary-key => True,
    auto-increment => True,
    type           => 'integer',
  },
  text => {
    type => 'text',
  },
];
