use strict;
use Test::More;
use Net::MPD;

my $mpd = Net::MPD->connect('radio.eatabrick.org');

isa_ok($mpd, 'Net::MPD');

my @status = $mpd->_send('status');
diag "$_" for @status;

done_testing;
