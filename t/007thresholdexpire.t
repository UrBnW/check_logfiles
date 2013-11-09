#!/usr/bin/perl -w
#
# ~/check_logfiles/test/007thresholdexpire.t
#
#  Test that all the Perl modules we require are available.
#  Simulate a portscan. Connections to port 80 are ok.
#

use strict;
use Test::More tests => 36;
use Cwd;
use Data::Dumper;
use lib "../plugins-scripts";
use Nagios::CheckLogfiles::Test;
use constant TESTDIR => ".";


#
# Count the hits, but reset the counter to 0 if an okpattern was found
#
# Case 1: nosavethresholdcount
#         reset
#         9 criticals, 2 warnings
#         run: OK
#         19 criticals, 12 warnings, 1 ok
#         run: OK
#         19 criticals, ok, 9 criticals
#         run: OK
#         19 criticals, ok, 19 criticals
#         run: CRITICAL (19)
# 
my $cl = Nagios::CheckLogfiles::Test->new({
  seekfilesdir => TESTDIR."/var/tmp",
  searches => [{
    tag => "nmap",
    logfile => TESTDIR."/var/adm/messages",
    criticalpatterns => [ 
        'connection refused', 
        'connection on port\s+\d+',
        'session aborted'
    ], 
    criticalexceptions => 'connection on port\s+80[^\d]*',
    criticalthreshold => 10,
    warningpatterns => [ 
        '.*total size is 0 .*', 
        'connection on port\s+80[^\d]*', 
    ],
    warningthreshold => 3,
    okpatterns => [
        'sshd restarted',
    ],
    options => 'criticalthreshold=10,warningthreshold=3,nosavethresholdcount',
  }]
});
my $nmap = $cl->get_search_by_tag("nmap");
$cl->reset();
$nmap->delete_logfile();
$nmap->delete_seekfile();
diag("deleted logfile and seekfile");
$nmap->trace("deleted logfile and seekfile");
$nmap->logger(undef, undef, 100, "connection refused");
diag("wrote 100 messages");
sleep 1;
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 0, 0, 0, 0)); ## reset run

$cl->reset();
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 9, "connection refused");  # skip 9 -> 0
$nmap->logger(undef, undef, 2, "connection on port 80"); # skip 2 -> 0
$cl->run();
diag(Data::Dumper::Dumper($nmap->{thresholdcnt}));
diag($cl->has_result());
diag($cl->{exitmessage});
diag("not enough errors/warnings");
ok($cl->expect_result(0, 0, 0, 0, 0));

$cl->reset();
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 19, "connection refused");  # skip 9, 1, skip 9 -> 1
$nmap->logger(undef, undef, 12, "connection on port 80"); # skip 2 -> 4
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 2, "sshd restarted");  # 0WC
$cl->run();
diag(Data::Dumper::Dumper($nmap->{thresholdcnt}));
diag($cl->has_result());
diag($cl->{exitmessage});
diag("no errors/warnings. have been resetted");
ok($cl->expect_result(0, 0, 0, 0, 0));

$cl->reset();
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 19, "connection refused");  # skip 9, 1, skip 9 -> 1
$nmap->logger(undef, undef, 2, "sshd restarted");  # 0WC
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 9, "connection refused");  # skip 9 -> 0
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
diag("no errors/warnings. have been resetted");
ok($cl->expect_result(0, 0, 0, 0, 0));

$cl->reset();
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 19, "connection refused");  # skip 9, 1, skip 9 -> 1
$nmap->logger(undef, undef, 2, "sshd restarted");  # 0WC
$nmap->loggercrap(undef, undef, 100);
$nmap->logger(undef, undef, 19, "connection refused");  # 
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 0, 1, 0, 2));

exit;
#
# Case 2: savethresholdcount
#         reset
#         9 criticals, 2 warnings
#         run: OK
#         19 criticals, 12 warnings, 1 ok
#         run: OK
#         19 criticals, ok, 9 criticals
#         run: OK
#         19 criticals, ok, 9 criticals
#         run: OK
#         19 criticals
#         run: CRITICAL (18)
# 


#
# threshold counters can expire
#
# options="criticalthreshold=10,thresholdexpiry=3600"
# a hit is not only counted, it gets a timestamp

# old counts are expired during load of the seekfile


