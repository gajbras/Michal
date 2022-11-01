#!/bin/bash
source /root/MMost/vars.sh

init_script

perl_inside='$lsrc=`ls -1 /var/log/data/inline/thirdparty.logs/ | wc -l`-3; while(<STDIN>) {if(/aggregate\s+t:\s+(\d+)\s+\((\d+)\)\s+p:\s+(\d+)\s+\((\d+)\)\s+w\/s 10m:\s+([0-9,.]*).*r\/s 10m:\s+([0-9,.]*)/) { $ftotl=$1; $hundredpercent=$2; $fproc=$3; $fprocp=$4; $ws10min=$5; $rs10min=$6; } } $ws10min=~s/,//; $rs10min=~s/,//; $processingspeed=0; if($ws10min!=0){$processingspeed=($rs10min/$ws10min);} $fratio=($ftotl/$lsrc); $status=":white_check_mark:"; if(($processingspeed<0.9) or ($fratio>1.5)){$status=":warning:";} if(($processingspeed<0.75) or ($fratio>2)){$status=":red_circle:";} ; printf "%s `%-32s R/W ratio: %2.2f` Files: %d, Write/10min: %3.0f, Read/10min: %3.0f\n", $status, $ARGV[0], $processingspeed, $ftotl, $ws10min , $rs10min;'
remote_command="/usr/local/bin/dssummary -i 0 -noc | /usr/bin/perl -e '$perl_inside'"

while IFS= read -r LINE
do
  if [[ $LINE =~ $LINE_REGEX ]] ; then
          NAME=${BASH_REMATCH[1]}
          IP=${BASH_REMATCH[2]}
          TYPE=${BASH_REMATCH[3]}

          if [[ $TYPE == "REC" || $TYPE == "ELMREC" ]] ; then
              if [[ $IP == "127.0.0.1" ]] ; then
                  eval $remote_command $HOST_NAME >> $INTERIM_FILE
              else
                  ssh -n root@$IP "$remote_command" "$NAME" >> $INTERIM_FILE
                  if (( $? > 0 )) ; then
                     echo ":skull_and_crossbones: \`$NAME\`" >> $INTERIM_FILE
                  fi
              fi
          fi

  fi
done < "$DEVICES"

template="PROCESINGSPEED"

sort -k2 -b -u < $INTERIM_FILE >> $OUTPUT_FILE

#MMOST_CHANNEL='vixieali-test'

${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "Processing Speed" < $OUTPUT_FILE

cleanup_script
