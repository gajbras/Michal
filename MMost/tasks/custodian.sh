#!/bin/bash
source /root/MMost/vars.sh

PWFIFO=$TMP_DIR/custodian

#trap ctrl_c INT
#function ctrl_c() {
#  echo "** Trapped CTRL-C"
#  rm $PWFIFO
#  exit 1
#}

[ -f $PWFIFO ] || mkfifo $PWFIFO
echo -n 'Enter complete authentication string in form of {"username":"c3...","password":"QS...","locale":"en_US","os":"Win32"}: '
read ENCODEDPASSWORD
clear
echo "Custodian running."
while /bin/true ; do
  echo $ENCODEDPASSWORD > $PWFIFO
  sleep 1
done
