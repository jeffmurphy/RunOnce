# $Header$
#
# RUNONCE.pm
#
# Jeff Murphy, copyright, license, etc, at bottom of file,
# or use
#
# perldoc RUNONCE.pm 
#

package RUNONCE;

use IO::Socket;
my $listen  = undef;
my $VERSION = 1.0;

sub D { 0; }

# ROUTINE
#   alreadyRunning(pidSocket, retries)
#
# DESCRIPTION
#   create a tcp socket on the given port.
#   if we can't, somebody else (another copy of
#   ourself, presumably, is running. print out
#   info about that copy.
# 
#   if successful, hold the port open until the
#   script exits to prevent another copy running
#   concurrently.
#
# AUTHOR
#   jeff murphy

sub alreadyRunning($$) {
	my ($ps, $rt) = (shift, shift);

	if(defined($ps)) {
		if(($ps =~ /^\d+$/) && ($ps <= 1024)) {
			die "RUNONCE::alreadyRunning() : socketNumber must > 1024";
		}
		# else, ps is probably a service name and not a port number
	} else {
		$ps = 16000; # default
	}

	$rt = 3 unless (defined($rt) && ($rt >= 0));
	my $pid;

	print "RUNONCE::alreadyRunning($ps, $rt)\n"
	  if &RUNONCE::D;

	for (my $i = 0; $i < $rt ; $i++) {
		print "\n\nalreadyRunning try #$i\n"
		  if &RUNONCE::D;

		$pid = RUNONCE::alreadyRunning2($ps);
		print "\nalreadyRunning2 returned $pid\n"
		  if &RUNONCE::D;
		return $pid if($pid != -1);
	}

	return $pid;
}

sub alreadyRunning2($) {
	my $ps = shift;
	my $mn = $0;
	if($mn =~ /([^\/]+)$/) {
		$mn = $1;
	} else {
		$mn = $0;
	}
	print "myname = $mn [$0]\n" if &RUNONCE::D;

	$RUNONCE::listen = IO::Socket::INET->new(Listen    => 16,
						 Proto     => 'tcp',
						 LocalAddr => '127.0.0.1',
						 LocalPort => $ps,
						 Reuse     => 1,
						 Timeout   => 1);
	if(!defined($RUNONCE::listen)) {
		my ($remoteName, $remotePid) = (undef,undef);
		my $c = IO::Socket::INET->new(Proto    => 'tcp',
					      PeerAddr => '127.0.0.1',
					      PeerPort => $ps,
					      Reuse    => 1,
					      Timeout  => 1);
		if(defined($c)) {
			my $l = $c->getline();

			if(!defined($l)) {
				# remote end closed cnx on us
				print "\$l !def, remote end closed cnx?\n"
				  if &RUNONCE::D;
				return -1;
			}

			chomp($l);
			print "remote sent \"$l\"\n" 
			  if &RUNONCE::D;

			if($l =~ /(\d+)\s(.*)/) {
				$remoteName = $2;
				$remotePid  = $1;

				# we read something that was parsable, 
				# but the remoteName doesnt match our
				# basename. this is a sanity check and
				# we punt if it fails.

				if($remoteName ne $mn) {
					warn "remoteName isnt what i expected.\nexpected=\"$mn\" got=\"$remoteName\"";
					return -1;
				}
			} else {
				# can't parse remote output
				warn "can't parse remote's message: \"$l\"";
				return -1;
			}
				
			$c->close();
		} else {
			print "cant connect to remote\n"
			  if &RUNONCE::D;
			$remotePid = -1;
		}

		print "remotePid = $remotePid remoteName = $remoteName\n"
		  if $RUNONCE::D;

		return $remotePid;
	}

	$RUNONCE::listen->blocking(0);
	return 0;
}

sub handleConnection {
	my $to  = $RUNONCE::listen->timeout(0);
	my $cnx = $RUNONCE::listen->accept();

	my $mn = $0;
	if($mn =~ /([^\/]+)$/) {
		$mn = $1;
	} else {
		$mn = $0;
	}
	print "myname = $mn [$0]\n" if &RUNONCE::D;

	if(defined($cnx)) {
		print "\naccepted incoming cnx. sending \"$$ $mn\"\n" 
		  if &RUNONCE::D;
		print $cnx "$$ $mn\n";
		$cnx->close();
	} else {
		print "\nno cnx to accept.\n" if &RUNONCE::D;
	}
	$RUNONCE::listen->timeout($to);
}

1;
__END__

=head1 NAME

RUNONCE::alreadyRunning - Routine for controlling mutually exclusive executions of the same program.

=head1 SYNOPSIS

   use RUNONCE;
   my $otherPid = RUNONCE::alreadyRunning(12345);
   die "another copy is currently running on pid $otherPid"
        if(defined($otherPid) && ($otherPid != 0));
       .
       .
       .

=head1 DESCRIPTION

C<RUNONCE::alreadyRunning> provides a mechanism for controlling
scripts that must be run with no concurrence. Typically, this 
is achieved by writing some sort of a lock file and aborting if
that file already exists, etc. 

Instead, we create a TCP server listening on a user-defined port 
(bound to the localhost interface). 

Since the kernel will only allow one application to bind to a 
specific TCP port, if the bind fails, we know another copy of 
our script is running and we abort. 

An advantage of this method is if our script aborts, we don't have 
to worry about cleaning the lockfile. The kernel handles freeing the
socket for re-use. 

=head1 USAGE

=over 4

=item handleConnection() returns NOTHING

     In order for RUNONCE to function correctly, you must 
     periodically call this routine. This routine need only
     be called by scripts that have successfully determined
     that they are running exclusively (see below).

     This routine handles connections from other instances
     of your script and is used to inform them that they are 
     not cleared to run exclusively. 

     An interesting side-effect of not calling this routine
     is that other instances of your script will queue up
     (hang) while they wait for the current instance to exit 
     and release the socket.

     If you have alot of scripts queued, the retry count (default 
     of 3 - see below) will eventually cause some of them to 
     die.

=item alreadyRunning(tcp_port, number_of_retries) returns INTEGER

     This routine performs the actual "is another copy of me running
     already" test. tcp_port number defaults to 16000, but you should
     definately override this. number_of_retries defaults to 3. 
     This routine will perform a sanity check incase somebody else
     as stolen our port.

     tcp_port 
              The port to bind to. you should 
              select a port that can be used exclusively
              by your script. You can alternately specify 
              a service name which might make things more
              managable (e.g. register a service with the 
              same name as your script and then pass basename
              of $0 as the tcp_port).

     number_of_retries
              There are at least two race conditions which
              could cause RUNONCE to be unsure of whether
              or not another copy is running. If we're unsure,
              we will retry a specified number of times. If
              we are still unsure we return -1

=back

=head1 RETURN VALUES

=over 4

=item -1  FATAL ERROR

      We can't be sure that another copy isn't running.

=item  0  SUCCESS

      Another copy is _not_ running, we've bound to the tcp
      port and your script is cleared to proceed.

=item  E<gt>0  FAILURE

      Another copy of the script is already running, this
      value is the process ID of the other copy.

=back

=head1 AUTHOR

Jeff Murphy E<lt>F<jcmurphy@jeffmurphy.org>E<gt>

=head1 COPYRIGHT

Copyright (c) 2001 Jeff Murphy E<lt>F<jcmurphy@jeffmurphy.org>E<gt>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
