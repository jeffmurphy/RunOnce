#!/usr/local/bin/perl -w
#
# $Header$
#
# NAME
#   test_wait_if_already_running.pl
#
# DESCRIPTION
#   if another copy of ourself is already running,
#   wait for it to complete and then proceed.
#
# AUTHOR
#   jeff murphy
#   jcmurphy@jeffmurphy.org
#
#       Copyright (c) 2001 Jeff Murphy <jcmurphy@jeffmurphy.org>.
#       All rights reserved.  This program is free software; you
#       can redistribute it and/or modify it under the same terms
#       as Perl itself.

use strict;
use lib '.';
use RUNONCE;

# pidSocket can be a service name or a port number

my $pidSocket = "runonce"; #16000;

print "Seeing if I'm already running...\n";
print "(If another copy is running, I'll hang until it completes.)\n";

my $pid = RUNONCE::alreadyRunning($pidSocket, 2);

if($pid > 0) {
	die "It looks like I'm already running. pid=$pid";
} elsif ($pid == -1) {
	# this usually means either
	#   (1) we couldnt connect to the remote end
	#       even tho we couldnt bind the socket.
	#       this is a race condition, the remote finishes,
	#       and releases the socket before we can connect to 
	#       it. to be more robust, you might want to try
	#       alreadyRunning() again and if it fails again, then
	#       abort. 
	#   (2) the remote end closed the connection while we were
	#       trying to read the pid. again, a race condition,
	#       re-try alreadyRunning().
	#
	# if you specify a retry > 0 (or use the default, which is
	# 3, then you should rarely get this error.

	die "An error occurred ($!)";
}

print "No. I'll sleep for 30 seconds. In another window,
run this script again while this one is still going.
\n";
$| = 1;
for(my $i = 30; $i > 0; $i--) {
	print "$i seconds left for pid $$   \r";
	sleep (1);

# the only difference between test_exit_if_already_running
# and this script is that we comment out this line:
#	RUNONCE::handleConnection();
}
print "\ndone.\n";

exit 0;


