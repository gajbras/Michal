#!/bin/bash
source /root/MMost/vars.sh

init_script

perl_inside='$nsout=`/usr/local/bin/NitroStarted 2>&1`; $nsout =~ s/^\s+|\s+$//g; $nsout =~ s/\n//g; $s=":white_check_mark:"; if($nsout ne 'Ok'){$s=":red_circle:";} printf("%s `%-32s %s`\n", $s,$ARGV[0], $nsout);';
remote_command="perl -e '$perl_inside'"

perl -e "$perl_inside" "$HOST_NAME" >> $INTERIM_FILE

while IFS= read -r LINE
do
  if [[ $LINE =~ $LINE_REGEX ]] ; then
          NAME=${BASH_REMATCH[1]}
          IP=${BASH_REMATCH[2]}
          TYPE=${BASH_REMATCH[3]}

          if [[ $TYPE != "ESM" ]] ; then
            do_ssh "$IP" "$NAME" "$INTERIM_FILE" "$remote_command"
          fi


  fi
done < "$DEVICES"

sort -k2 -b -u < $INTERIM_FILE >> $OUTPUT_FILE

template="GREEN"
((`grep -c ':warning:' $INTERIM_FILE` > 0 )) && template='YELLOW'
((`grep -c ':hourglass' $INTERIM_FILE` > 0 )) && template='RED'
((`grep -c ':red' $INTERIM_FILE` > 0 )) && template='RED'
((`grep -c ':skull' $INTERIM_FILE` > 0 )) && template='RED'


#MMOST_CHANNEL='vixieali-test'

${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "NitroStarted" < $OUTPUT_FILE

cleanup_script
