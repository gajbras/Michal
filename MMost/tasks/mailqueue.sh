#!/bin/bash
source /root/MMost/vars.sh

init_script


# execution


nr_messages=`/usr/local/bin/nquery -d esm -q 'select count(*) from triggeredcondition' 2> /dev/null | tail -n +2`
echo "**Number of messages** $nr_messages" >> $OUTPUT_FILE


if (( nr_messages > 0 )) ; then
  echo "**Oldest Undelivered Messages** (max 3 displayed)" >> $OUTPUT_FILE

  echo >>  $OUTPUT_FILE
  echo "|Triggered Alarm ID |Check Time (in UTC)|Notification ID|Notification Name|" >> $OUTPUT_FILE
  echo "|------------------:|-------------------|--------------:|-----------------|" >> $OUTPUT_FILE
  /usr/local/bin/nquery -d esm -q 'select t.TriggeredAlarmID,t.CheckTime,t.notificationid,n.name from triggeredcondition t, notification n where t.notificationid (+) = n.id limit 3 order by t.CheckTime asc' 2>/dev/null | tail -n +2 | perl -e 'while(<STDIN>){if(/(\d+)\|([^|]+)\|(\d+)\|(.+)/){print "|$1|$2|$3|$4|\n";}}' >> $OUTPUT_FILE

  echo >>  $OUTPUT_FILE
  echo "**Undelivered Messages Aggregation**" >> $OUTPUT_FILE

  echo >>  $OUTPUT_FILE
  echo "|Notification ID|Notification Name|Group Count|" >> $OUTPUT_FILE
  echo "|--------------:|-----------------|----------:|" >> $OUTPUT_FILE
  /usr/local/bin/nquery -d esm -q 'select t.notificationid, n.name, count(*) as how_many from triggeredcondition t, notification n where t.notificationid (+) = n.id group by n.name, t.notificationid order by how_many desc' 2>/dev/null | perl -e 'while(<STDIN>){if(/(\d+)\|([^|]+)\|(\d+)/){print"|$1|$2|$3|\n";}}' >> $OUTPUT_FILE

  echo "**In Other News**" >> $OUTPUT_FILE
  echo '```' >> $OUTPUT_FILE
  /usr/local/bin/nquery -d esm -q 'select count(*) from sendemail' >> $OUTPUT_FILE 2>&1
  /usr/local/bin/nquery -d esm -q 'select count(*) from triggeredalarm' >> $OUTPUT_FILE 2>&1
  echo '```' >> $OUTPUT_FILE
fi

template="GREEN"
if (( nr_messages > 2 )) ; then template="YELLOW" ; fi
if (( nr_messages > 50 )) ; then template="RED" ; fi

#MMOST_CHANNEL='vixieali-test'
${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "ESM Mail Queue" < $OUTPUT_FILE

cleanup_script
