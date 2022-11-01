#!/bin/bash
source /root/MMost/vars.sh

init_script


/root/MMost/tasks/deviceslist.pl > ${TMP_DIR}/deviceslist.lst 2>${TMP_DIR}/deviceslist.log

# name="FITEIPSM01A.ss.tieto.local" zoneId="0" zoneName="" parentId="" enabled="1" childEnabled="0" childCount="0" childType="0" url="" collector="syslog" parser="asp"  require_tls="F" pool="Tieto Security" nitro_formated_file_xsum="no" nitro_formated_file="no" mask="0" linked_ipsid="144132785026629632" exportNitroFile="F" autolearn="F" type="49190" elm_logging="T" els_logging="F" hostname="FITEIPSM01A" parsing="T" tz_id="Europe/Helsinki" ClientCount="0" ChildType="0" GUID="ACDE449F-BC79-492F-56B7-E363AC120A90" ERCIPSID="144132780261900288" syslog_port="514"


grep 'zoneName=""' ${TMP_DIR}/deviceslist.lst | # Show lines with empty zone name
  grep -v 'collector="ace"' | # Ignore CRL
  grep -v 'childEnabled="1"' | # Ignore childEnabled
  grep 'parsing="T"' > $INTERIM_FILE # pass only parsing devices

echo '```rust' >  $OUTPUT_FILE
sort -u < $INTERIM_FILE >> $OUTPUT_FILE
echo '```' >> $OUTPUT_FILE
grep -C2 'ERROR' ${TMP_DIR}/deviceslist.log >> $OUTPUT_FILE

nr_messages=`wc -l $OUTPUT_FILE | cut -d' ' -f1`

template="GREEN"
if (( nr_messages > 2 )) ; then template="YELLOW" ; fi
if (( nr_messages > 3 )) ; then template="RED" ; fi


#MMOST_CHANNEL='vixieali-test'
${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "Devices With Missing Zone" < $OUTPUT_FILE

cleanup_script
