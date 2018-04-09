#!/opt/perl/bin/perl
#
# nettest.pl
#

use IO::Socket;
use Errno;
$| = 1;


use IO::Socket;
use Errno;
$| = 1;

$host = shift;
$port = shift;
$type = shift || "tcp";
$test = shift || "X";        ## "C" for Continuous testing
die "No Host parameter!" if !$host;
die "No Port parameter!" if !$port;

while (true) {
   my $rc = new IO::Socket::INET
         PeerAddr => $host,
         PeerPort => $port,
         Proto  => $type,
         Timeout => 2;
   if ($type eq "udp" or $type eq "UDP") {      ## UDP Socket
     my $buf;
     $rc->send("--TEST LINE--") or die "Send Error: $!\n";
     eval {
       local $SIG{ALRM} = sub { die "-Timeout-\n" };
       alarm 2;
       $rc->recv($buf,1000);
       alarm 0;
       print "Success connecting to $host on port: $port\n";
     };
     if ($@ eq "-Timeout-\n") {
       print "Cannot Connect: Timeout!\n";
     }
   } else {     ## TCP Socket
     if ($!{EISCONN}) { ## Connected!!
       print "Success connecting to $host on port: $port\n";
     } else {
        if ($!{EINVAL})  {  ## "Invalid Argument" => Connection Refused
           print "Cannot Connect: CONNECTION REFUSED!\n";
        }
        if ($!{ENOTCONN} || $!{ETIMEDOUT}) {  ## NotConnected or Timed Out, Error.
           print "Cannot Connect: -$!\n";
        }
        if ($!{EALREADY} || $!{EINPROGRESS}) { ## InProgress or Already Started, try again.
           close $rc;
           my $rc = new IO::Socket::INET
              PeerAddr => $host,
              PeerPort => $port,
              Proto  => $type,
              Timeout => 4;
           if ($!{EISCONN}) {
              print "Success connecting to $host on port: $port\n";
           }
           print "Cannot Connect to $host on port: $port\n"
        } else {
           ## Unknown Error
 print "Cannot Connect: {$!}\n";
        }
     }
   }
   close $rc;
   if ($test ne "C") {
     exit;
   }
   sleep 1;
}

              
