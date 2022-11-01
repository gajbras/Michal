#!/bin/bash
source /root/MMost/vars.sh

init_script

perl_inside='use File::Basename;foreach(`/usr/local/bin/tq`){ if(/^\s*((\S+\s?)+)\s{2,}(\d+)\s+/){ $tq{$3}=$1;}} while(<STDIN>){ if(/(\d+)\s+(\S+)/) { $m=int($1/1024); $dn=$2; ($num,$path,$suffix)=fileparse($dn); $s=":white_check_mark:"; if($m>300){ $s=":warning:"; $war++; } if($m>700){ $s=":red_circle:"; $war--; $rcir++; } $out=sprintf("%s `%-32s %-40s %-6d %5d MB` %s", $s,$ARGV[0], $tq{$num}, $num, $m); } } print $out; if($rcir>0){print "$rcir :red_circle:  "} if($war>0){print "$war :warning:";} print "\n";'
remote_command="du -s /var/log/data/inline/thirdparty.logs/* | sort -n | grep -v elm | perl -e '$perl_inside'"

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

sort -k2 -b -u < $INTERIM_FILE >> $OUTPUT_FILE

template="NEUTRAL"

#MMOST_CHANNEL='vixieali-test'

${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "Processing Queue thirdparty.logs" < $OUTPUT_FILE

cleanup_script
