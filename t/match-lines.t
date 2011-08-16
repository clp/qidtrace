use strict;
use warnings;

use Test::More tests => 12;

use Sendmail::QidTrace qw/match_line/;

my @tests =
(
 {
  d => 'typical log line',
  l => 'Jan  5 00:15:33 b.mx.example.net sendmail[13960]: jB4JCnPo019367: to=<u3814@h1250.com>, delay=3+13:01:56, xdelay=00:00:00, mailer=esmtp, pri=45751020, relay=relay_id dsn=4.0.0, stat=Deferred: Connection timed out with somewhereelse.com.',
  e => 'u3814@h1250.com',
  i => 'jB4JCnPo019367',
 },
 {
  d => 'normal line with no email fields',
  l => 'Jan  5 00:15:33 d.mx.example.net sm-mta[15617]: jB88Ehn2015617: Milter add: header: X-example-SB-Tests: cn ',
  e => '',
  i => 'jB88Ehn2015617',
 },
 {
  d => q{"<qid> bounced because of" log line},
  l => 'fang.pl[29063]: jB88DJCg012023 bounced because of virus Worm.Mytob.IC ',
  #ORG.now.fails  e => 'Worm.Mytob.IC',
  e => '',
  i => 'jB88DJCg012023',
 },
 {
  d => q{"account on <qid>" log line},
  l => 'fang.pl[30547]: Skipping header checks for spam-troll account on jB88DhoI012747. ',
  e => '',
  i => 'jB88DhoI012747',
 },
 {
  d => 'from field exists, but is the empty string',
  l => 'Jan  5 00:15:33 a.mx.example.net sm-mta[15727]: jB88FNku015727: from=<>, size=1871, class=0, nrcpts=0, proto=ESMTP, daemon=MTA, relay=relay_id [10.11.12.13] ',
  e => '',
  i => 'jB88FNku015727',
 },
 {
  d => 'tag less (no from=<email> or to=<email>) email address',
  l => 'Jan  5 00:15:33 b.mx.example.net sm-mta[11771]: jB88FHZe011771: <u9163@h27.com>... No such user here',
  e => 'u9163@h27.com',
  i => 'jB88FHZe011771',
 },
);

for my $t (@tests) {
    my ($e, $i) = match_line $t->{e}, $t->{l};
    is $e, $t->{e}, "email matches: for $t->{d}";
    is $i, $t->{i}, "  qid matches: for $t->{d}";
}
