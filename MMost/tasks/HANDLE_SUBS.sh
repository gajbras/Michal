#!/bin/bash
#
# This script has nothing to do with MMost. It is only one-time tool to distribute Update file via scp.
# DO NOT put it to crontab !
#

source /root/MMost/vars.sh

init_script


# execution


while IFS= read -r LINE
do
  if [[ $LINE =~ $LINE_REGEX ]] ; then
          NAME=${BASH_REMATCH[1]}
          IP=${BASH_REMATCH[2]}
          TYPE=${BASH_REMATCH[3]}

          if [[ $TYPE == "REC" || $TYPE == "ELMREC" || $TYPE == "ACE" || $TYPE == "ELM" ]] ; then
          #if [[ $TYPE == "REC" ]] ; then
                  echo -n '### '  | tee -a $OUTPUT_FILE
                  date | tee -a $OUTPUT_FILE
                  echo -n '### '  | tee -a $OUTPUT_FILE
                  echo $NAME | tee -a $OUTPUT_FILE
#                  ssh -n root@$IP 'cp -av /root/.ssh /root/.ssh-220119' | tee -a $OUTPUT_FILE
                  scp -v /root/RECEIVER_Update_11.5.4.signed.tgz  root@$IP:/usr/local/NitroGuard/ | tee -a $OUTPUT_FILE
                  ssh -n root@$IP 'cat /etc/buildstamp' | tee -a $OUTPUT_FILE
          fi




  fi
done < "$DEVICES"


template="NEUTRAL"

#MMOST_CHANNEL='vixieali-test'
#${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "$HOST_NAME $0" --title "The Handler" < $OUTPUT_FILE

#cleanup_script
