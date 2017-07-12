#!/bin/ksh

echo "Demarrage de l utilitaire archiveBackup"

. /usr/swa/alliance_init -S
. $ALLIANCE/bin/orains_env.ksh
#. $ALLIANCE/INA/bin/$ARCH/xterm_init
export LD_LIBRARY_PATH=$ALLIANCE/common/lib/$ARCH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ALLIANCE/BSS/lib/$ARCH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$LD_LIBRARY_PATH

dateFormat=`date '+%Y%m%d'`
day=`date '+%d'`
dayInWeek=`date '+%w'`

mailDest=`nawk -F"=" '{ if ($1=="MAIL_DEST") {print $2;exit}}' config.ini`
nameFileLog=$dayInWeek".log"

# Lancement du script perl                       
perl dumpAndBackup.pl 2>&1 > ./log/$nameFileLog 
if [ $? -ne 0 ]
        then
                echo "Error on execute perl script"
                cd ./log/
                (uuencode $nameFileLog $nameFileLog)| mailx -s "Archive Backup [Error]" $mailDest
                cd .. 
                exit 255
fi

cd ./log/
(uuencode $nameFileLog $nameFileLog)| mailx -s "Archive Backup [Success]" $mailDest
cd ..

