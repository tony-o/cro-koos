use Koos::Row;
unit class Row::Token does Koos::Row;

method refresh-expiration($time = 60*24*30) {
  self.expires(time + $time);
  self.update;
}
