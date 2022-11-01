#!/bin/bash
source /root/MMost/vars.sh

init_script


# execution

/usr/local/bin/NitroTID -d sfx -t alert -4 >$INTERIM_FILE

/root/MMost/tasks/nitrotid.pl <$INTERIM_FILE >$OUTPUT_FILE

grep -i error $INTERIM_FILE >> $OUTPUT_FILE

template="GREEN"
if (( `grep -c ':warning:' $OUTPUT_FILE` > 0 )) ; then template="YELLOW" ; fi
if (( `grep -c ':red_circle:' $OUTPUT_FILE` > 0 )) ; then template="RED" ; fi
if (( `grep -c -i 'error' $OUTPUT_FILE` > 0 )) ; then template="RED" ; fi

#MMOST_CHANNEL='vixieali-test'
${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "NitroTID" < $OUTPUT_FILE

cleanup_script
