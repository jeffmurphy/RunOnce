## SYNOPSIS

```perl
          use RUNONCE;
          my $otherPid = RUNONCE::alreadyRunning(12345);
          die "another copy is currently running on pid $otherPid"
               if(defined($otherPid) && ($otherPid != 0));
              .
              .
              .
```

## DESCRIPTION

       "RUNONCE::alreadyRunning" provides a mechanism for controlling scripts
       that must be run with no concurrence. Typically, this is achieved by
       writing some sort of a lock file and aborting if that file already
       exists, etc.

       Instead, we create a TCP server listening on a user-defined port (bound
       to the localhost interface).

       Since the kernel will only allow one application to bind to a specific
       TCP port, if the bind fails, we know another copy of our script is
       running and we abort.

       An advantage of this method is if our script aborts, we don't have to
       worry about cleaning the lockfile. The kernel handles freeing the
       socket for re-use.
