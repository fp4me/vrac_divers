#Author : Francois LEBOT

use Time::Local;
use POSIX qw/strftime/;

use constant false => 0; 
use constant true  => 1; 

my %config;

sub getTimeNow {
return strftime "%y%m%d%H%M", localtime time() ;
}

sub loadConfig {
 open my $input, "<", "config.ini" or die "Couldn't open config.ini: $!\n";
 while(<$input>) {
  chomp;
  if ( /^([^=]+)=(.*)$/) {
     $config{$1} = $2;
  }
 }
close($input) or die $!;
}


sub getConfigValue {
my $key = $_[0];
my $value = $config{$key};
if (length($value) eq 0) {die "Parameter[$key] not found or empty value";}
return $value
}

sub trace {
$text = $_[0];
my $now = time();
print "[",scalar localtime $now,"] $text\n";
}

sub traceOut {
@text = @{$_[0]};
foreach my $lineout (@text) {
print "  [*] $lineout";
}
}

sub cmdLogAndExec {
$cmd = $_[0];
trace " * $cmd";
@resCmd = `$cmd`;
traceOut \@resCmd;
return @resCmd;
}

loadConfig;

my $dirAlliance = $ENV{ALLIANCE};
my $dirRlsBin = "$dirAlliance/bin";
my $dirSAADUMP = getConfigValue("DIRSAADUMP");
my $dirGZIP = getConfigValue("DIRGZIP");
my $dirJRAR = getConfigValue("DIRJRAR");
my $dirMEAR = getConfigValue("DIRMEAR");
my $dirBackupEJA = getConfigValue("DIRBCKEJA");
my $dirBackupMFA = getConfigValue("DIRBCKMFA");
my $retBackupEJA = getConfigValue("RETBCKEJA") + 0;
my $retBackupMFA = getConfigValue("RETBCKMFA") + 0;
my $retMesg = getConfigValue("RETMESG") + 0;
my $dirTMP = "$dirSAADUMP/tmp";
my $mailDest = getConfigValue("MAIL_DEST");

trace "Demarrage de l utilitaire";
trace "-------- CONFIG --------";
trace "dirAlliance[$dirAlliance]";
trace "dirRlsBin[$dirRlsBin]";
trace "dirGZIP[$dirGZIP]";
trace "dirSAADUMP[$dirSAADUMP]";
trace "dirTMP[$dirTMP]";
trace "dirJRAR[$dirJRAR]";
trace "dirMEAR[$dirMEAR]";
trace "dirBackupEJA[$dirBackupEJA]";
trace "dirBackupMFA[$dirBackupMFA]";
trace "retBackupEJA[$retBackupEJA]";
trace "retBackupMFA[$retBackupMFA]";
trace "-----------------------";

sub backupEJA {
my $archiveName = $_[0];
cmdLogAndExec "$dirRlsBin/saa_system archive backup jrnl $archiveName $dirBackupEJA" ;
$? == 0 or die "error[$!] on backup EJA [$archiveName] to [$dirBackupEJA]";
}

sub backupMFA {
my $archiveName = $_[0];
cmdLogAndExec "$dirRlsBin/saa_system archive backup mesg $archiveName $dirBackupMFA" ;
$? == 0 or die "error[$!] on backup MFA [$archiveName] to [$dirBackupMFA]";
}

sub removeEJArchive {
my $archiveName = $_[0];

#check de la date 
if ($archiveName =~ /^(\d{4})(\d{2})(\d{2})$/) {
  $day   = $3;
  $month = $2;
  $year =  $1;

  my $timeArchive = timelocal(59,59,23,$day,$month-1,$year); 
  my $timeRetention = time() -  (($retBackupEJA+1)*24*60*60); 

  if ($timeArchive < $timeRetention) { 

    #test de l existence du backup 
    if (-e "$dirBackupEJA/JRAR_$archiveName") {
      trace ">>> remove archive EJA [$archiveName]"; 
      cmdLogAndExec  "$dirRlsBin/saa_system archive remove jrnl $archiveName"  ;
      $? == 0 or die "error[$!] on remove archive EJA [$archiveName]";
     } else { die "Archive EJA [$archiveName] cannot be remove; backup directory  not found"; }
  }

} else { die "bad archive name[$archiveName]" }

}

sub getCmdDumpJrnl {
my $archiveName = $_[0];
my $cmdDumpJrnl = "$dirSAADUMP/saa_dump -f -e jrnl -o $dirTMP -n $archiveName 2>&1";
return $cmdDumpJrnl
}

sub getCmdDumpMesg {
my $archiveName = $_[0];
my $cmdDumpMesg = "$dirSAADUMP/saa_dump -f -e mesg -o $dirTMP -n $archiveName 2>&1";
return $cmdDumpMesg
}

sub tarAndGzipJRAR {
my $archiveName = $_[0];
my $archiveDay = substr $archiveName,2;
my $dateJRAR = getTimeNow();

chdir($dirTMP) or die "error [$!] on change dir to [$dirTMP] " ;

cmdLogAndExec "tar -cvf JRAR_${dateJRAR}_${archiveDay} $archiveName";
  $? == 0 or die "error [$!] on tar [$archiveName] " ;

cmdLogAndExec "$dirGZIP JRAR_${dateJRAR}_${archiveDay}";
  $? == 0 or die "error [$!] on gzip [JRAR_${dateJRAR}_${archiveDay}] " ;

`rm -R $archiveName`;
chdir($dirSAADUMP);
return "JRAR_${dateJRAR}_${archiveDay}.gz";
}

sub tarAndGzipMEAR {
my $archiveName = $_[0];
my $archiveDay = substr $archiveName,2;
my $dateMEAR = getTimeNow();

chdir($dirTMP) or die "error [$!] on change dir to [$dirTMP] " ;

cmdLogAndExec "tar -cvf MEAR_${dateMEAR}_${archiveDay} $archiveName";
  $? == 0 or die "error [$!] on tar [${archiveName}] " ;

cmdLogAndExec "$dirGZIP MEAR_${dateMEAR}_${archiveDay}";
  $? == 0 or die "error [$!] on gzip [MEAR_${dateMEAR}_${archiveDay}] " ;

`rm -R $archiveName`;
chdir($dirSAADUMP);
return "MEAR_${dateMEAR}_${archiveDay}.gz";
}

sub moveJRARtoDest {
my $FileNameToMove = $_[0];
cmdLogAndExec "mv $dirTMP/$FileNameToMove $dirJRAR";
$? == 0 or die "error [$!] on move $FileNameToMove  to $dirJRAR" ;
}

sub moveMEARtoDest {
my $FileNameToMove = $_[0];
cmdLogAndExec "mv $dirTMP/$FileNameToMove $dirMEAR";
$? == 0 or die "error [$!] on move $FileNameToMove  to $dirMEAR" ;
}

# Gestion des Archives EJA ########################################################
trace "--- Recuperation de la liste des archives journals en base ---";
my @cmdListJrnl = cmdLogAndExec "$dirRlsBin/saa_system archive list jrnl ";
$? == 0 or die "error [$!] on execute saa_system archive list jrnl command " ;

my $cntArchJrnlReady = 0;
my $cntArchJrnlDone = 0;
foreach my $line (@cmdListJrnl) {
 if($line =~ /^(\d{8})\s\[([^\]]+)\]$/) { 
    $date = $1; $status = $2; 
    if ($status eq "Ready") { 
      $cntArchJrnlReady++; 
      trace "archive[$date] a traiter";

      # dump de journal event ################
      trace ">>> dump de l archive";
      $cmdDumpJrnl = getCmdDumpJrnl($date); 
      trace $cmdDumpJrnl ;
      my @resCmdDumpJrnl = `$cmdDumpJrnl`;  
      traceOut \@resCmdDumpJrnl;      
      $? == 0 or die "error [$!] on execute $cmdDumpJrnl " ;

      # tar/gzip et move de larchive ############
      trace ">>> tar/gzip and move de larchive";
      moveJRARtoDest(tarAndGzipJRAR($date));

      # l archive JRAR a ete traite, le backup EJA peut etre lance ##########
      trace ">>> backup de l EJA";
      backupEJA($date)

  }
  else { $cntArchJrnlDone++; 
         removeEJArchive($date);
       }
} 
}

trace "[$cntArchJrnlReady] EJA traitees" ;
trace "[$cntArchJrnlDone] EJA  deja traitees" ;

# Gestion des Archives MSG  ########################################################

trace  "--- Archivage des messages  ---";
my @cmdArchMesg = cmdLogAndExec "$dirRlsBin/saa_system archive mesg -days $retMesg 2>&1";
$? == 0 or die "error [$!] on execute saa_system archive mesg command " ;
my $successful = false;
my $found = false;
my $old_date="";
foreach my $line (@cmdArchMesg) {
 if($line =~ /^([^\.]+)\.([^\.]+)\. Date range is ([^\.]+)\.$/) { 
   if ($3 =~ /^([0123456789\/]+) - ([0123456789\/]+)$/ ) {
      $old_date = $1; 
    }
$found  = true;
 }
 if ($line =~ /^SUCCESSFUL$/) { $successful = true; }
}
unless ($successful) {
 if ($found)  {
                my $message="Some message from [$old_date] need to be completed" ;
                my $subject="[Warning] Uncomplete Archive Process";
                my @mail = `(echo "$message")| mailx -s "$subject" $mailDest`; 
                $? == 0 or die "error [$!] on mail for warning on incomplete archive process " ;
              }
}

trace  "--- Recuperation de la liste des archives messages  en base ---";
@cmdListMesg = cmdLogAndExec "$dirRlsBin/saa_system archive list mesg ";
$? == 0 or die "error [$!] on execute saa_system archive list mesg command " ;

my $cntArchMesgReady = 0;
my $cntArchMesgDone = 0;

foreach my $line (@cmdListMesg) {
 if($line =~ /^(\d{8})\s\[([^\]]+)\]$/) { 
    $date = $1; $status = $2; 
    if ($status eq "Ready") { 
      $cntArchMesgReady++; 
      trace "archive[$date] a traiter";

      # dump de l archive mesg ############
      trace ">>> dump de l archive";
      $cmdDumpMesg = getCmdDumpMesg($date); 
      trace $cmdDumpMesg ;
      my @resCmdDumpMesg = `$cmdDumpMesg`;  
      traceOut \@resCmdDumpMesg;      
      $? == 0 or die "error [$!] on execute $cmdDumpMesg " ;

      # tar/gzip et move de larchive ########
      trace ">>> tar/gzip and move de larchive";
      moveMEARtoDest(tarAndGzipMEAR($date));

      # l archive MEAR a ete traite, le backup MFA peut etre lance ############
      trace ">>> backup de l MFA";
      backupMFA($date)

  }
  else { $cntArchMesgDone++; 
         #removeMFArchive($date);
       }
} 
}

trace "[$cntArchMesgReady] MFA traitees" ;
trace "[$cntArchMesgDone] MFA  deja traitees" ;

 
