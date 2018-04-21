use Koos::Model;
unit class Model::User does Koos::Model['user'];

has @.columns = [
  user_id => {
    is-primary-key => True,
    auto-increment => True,
    type           => 'integer',
  },
  username => {
    type   => 'varchar',
    length => 64,
  },
  email => {
    type   => 'varchar',
    length => 128,
  },
  password => {
    type   => 'varchar',
    length => 256,
  },
];

has @.relations = [
  tokens => { :has-many, :model<Token>, :relate(user_id => 'user_id'), },
];
