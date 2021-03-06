#!/usr/bin/perl -w
#
# ~/check_logfiles/test/040eventlog.t
#
#  Test that all the Perl modules we require are available.
#

use strict;
use Test::More;
use Cwd;
use lib "../plugins-scripts";
use Nagios::CheckLogfiles::Test;
use Nagios::CheckLogfiles::Search::Eventlog;
use constant TESTDIR => ".";

if (($^O ne "cygwin") and ($^O !~ /MSWin/)) {
  diag("this is not a windows machine");
  plan skip_all => 'Test only relevant on Windows';
} else {
  plan tests => 6;
}

my $cl = Nagios::CheckLogfiles::Test->new({
	seekfilesdir => TESTDIR."/var/tmp",
	searches => [
	    {
	      tag => "ssh",
	      type => "wevtutil",
              criticalpatterns => ["Adobe", "Firewall" ],
              warningpatterns => ["Battery low" ],
              wevtutil => {
              	eventlog => "application",
              }
	    }
	]    });
my $ssh = $cl->get_search_by_tag("ssh");
$ssh->delete_seekfile();
$ssh->trace("deleted seekfile");

# 1 logfile will be created. there is no seekfile. position at the end of file
# and remember this as starting point for the next run.
$ssh->trace(sprintf "+----------------------- test %d ------------------", 1);
sleep 2;
$ssh->trace("initial run");
$cl->run(); # cleanup
$cl->reset();
diag("cleanup");
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 0, 0, 0, 0));

# 2 now find the two criticals
$ssh->trace(sprintf "+----------------------- test %d ------------------", 2);
$cl->reset();
sleep 30;
$ssh->logger(undef, undef, 1, "Firewall problem");
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 0, 0, 0, 0));

# 3 now find the two criticals and the two warnings
$ssh->trace(sprintf "+----------------------- test %d ------------------", 3);
$cl->reset();
sleep 120;
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 0, 1, 0, 2));

# 2 now find the two criticals
$ssh->trace(sprintf "+----------------------- test %d ------------------", 4);
$cl->reset();
$ssh->logger(undef, undef, 1, "Firewall problem");
sleep 10;
$ssh->logger(undef, undef, 1, "Firewall problem");
sleep 10;
$ssh->logger(undef, undef, 1, "Firewall problem");
sleep 10;
$ssh->logger(undef, undef, 1, "Firewall problem");
sleep 10;
$ssh->logger(undef, undef, 1, "Firewall problem2");
$ssh->logger(undef, undef, 1, "Firewall problem");
sleep 10;
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
#ok($cl->expect_result(0, 0, 6, 0, 2));
$cl->{perfdata} =~ /.*ssh_criticals=(\d+).*/;
my $found = $1;
diag(sprintf "reported %d errors so far. %d to come", $found, 6 - $found);
ok($cl->{exitmessage} =~ /CRITICAL/);

# 3 now find the two criticals and the two warnings
$ssh->trace(sprintf "+----------------------- test %d ------------------", 5);
$cl->reset();
sleep 65;
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
if ($found == 6) {
ok($cl->expect_result(0, 0, 0, 0, 0));
} else {
ok($cl->expect_result(0, 0, 6 - $found, 0, 2));
}
$ssh->logger(undef, undef, 2, "Alert: Battery low");
sleep 1;
$cl->run();
diag($cl->has_result());
diag($cl->{exitmessage});
ok($cl->expect_result(0, 2, 0, 0, 1));


