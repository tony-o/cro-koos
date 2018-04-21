use Koos::Model;
unit class Model::Token does Koos::Model['token', 'Row::Token'];

has @.columns = [
  token_id => {
    auto-increment => 1,
    is-primary-key => 1,
    type           => 'int',
  },
  user_id => {
    type => 'int',
  },
  expires => {
    type => 'timestamp',
  },
  token => {
    type => 'varchar',
    length => 64,
  },
];

has @.relations = [
  user => { :has-one, :model<User>, :relate(user_id => 'user_id'), },
];

method generate($user-id) {
  my $user = self.dbo.model('User').search({
    user_id => $user-id,
  }).first;
  die "User not found: $user-id"
    unless defined $user;
  my $token;
  repeat {
    $token = ('a'..'z','A'..'Z','0'..'9','!'..'+').flat.roll(64).join;
  } while self.search({ token => $token }).count != 0;
  my $new-token = self.new-row({
    user_id => $user.user_id,
    expires => time + (60*24*30), # 30 days
    token   => $token,
  });
  $new-token.update;
  $new-token;
}

method valid {
  self.search({ expires => { '>' => time + 60 }, });
}
