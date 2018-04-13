use Cro::HTTP::Router;
module Ctrl::Greet {

  our sub greet('greet', $word, :$req = request) {
    my $data = $req.model('Data').new-row;
    $data.text($word);
    $data.update;
    my $active = $req.model('Data').search({ text => $word }).count;
    content 'text/plain', "Hello $word! ($active $word\'s)";
  }

  our sub bye('bye', $word, :$req = request) {
    my $deleted = $req.model('Data').search({ text => $word }).count;
    $req.model('Data').search({ text => $word }).delete;
    content 'text/plain', "Good bye $word! (deleted $deleted rows)";
  }

}
