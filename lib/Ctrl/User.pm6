use Cro::HTTP::Router;
use Crypt::Libcrypt;
unit module Ctrl::User;

our sub create('user', 'create', :$req = request) {
  request-body -> %param {
    my $urs    = $req.model('User');
    my $exists = $urs.search($( '-or' => [
      { username => %param<username>, },
      { email    => %param<email>, },
    ])).first;
    my %response;
    if !defined $exists {
      $exists      = 0;
      my $salt     = ('a'..'z','A'..'Z','0'..'9').flat.roll(8).join;
      my $password = $salt ~ ':' ~ crypt(%param<password>, '$1$'~$salt~'$');
      $exists = $urs.new-row;
      $exists.username(%param<username>);
      $exists.password($password);
      $exists.email(%param<email>);
      $exists.update;
      $exists = $req.model('Token').generate($exists.user_id).as-hash;
      %response = (
        token   => $exists<token>,
        expires => $exists<expires>,
      );
      $exists = 0;
    } else {
      $exists = $exists.username eq %param<username>
        ?? 100
        !! 101;
    }
    my %errors = (
      0   => 'Successfully created user',
      100 => 'Username is already taken',
      101 => 'Email address is in use',
    );
    content 'application/json', {
      %response, 
      success => ($exists == 0),
      message => %errors{$exists},
    };
  }
}

sub check-token($req, $token, :$auto-respond = True) is export {
  my $trs = $req.model('Token');
  my $tok = $trs.search({ token => $token }).first;
  if !$tok || $tok.expires <= time {
    return content 'application/json', {
      success => False,
      message => 'Not a valid token',
    } if $auto-respond;
    return;
  }
  $tok.refresh-expiration;
  [$tok.user, $tok];
}

sub check-user($req, %param) {
  return content 'application/json', {
    success => False,
    message => 'Token request must provide <username>|<email> and <password>',
  } unless (defined %param<username> || defined %param<email>) && defined %param<password>;
  my $urs = $req.model('User');
  my %flt;
  %flt<username> = %param<username> if defined %param<username>;
  %flt<email>    = %param<email>    if defined %param<email>;
  my $usr = $urs.search(%flt).first;
  return content 'application/json', {
    success => False,
    message => 'User/pass combination not found',
  } unless defined $usr;
  my ($salt, $hash) = $usr.password.split(':', 2);
  my $exp = crypt(%param<password>, '$1$'~$salt~'$');
  return content 'application/json', {
    success => False,
    message => 'User/pass combination not found',
  } unless $hash eq $exp;
  $usr;
}

our sub request-token('user', 'request-token', :$req = request) {
  request-body -> %param {
    my $usr = check-user($req, %param);
    return unless $usr;
    my $tok = $usr.tokens.valid.count
      ?? $usr.tokens.valid.first
      !! $req.model('Token').generate($usr.user_id);
    $tok.refresh-expiration;
    content 'application/json', {
      success => True,
      token   => $tok.token,
      expires => $tok.expires,
    };
  };
}

our sub remove-tokens('user', 'remove-tokens', :$req = request) {
  request-body -> %param {
    my $usr = check-user($req, %param);
    return unless $usr;
    $usr.tokens.search({ expires => { '<=' => time }, }).delete;
    my $count = $usr.tokens.count;
    $usr.tokens.delete;
    content 'application/json', {
      success => True,
      message => "Deleted $count acceptable tokens",
    };
  };
}
