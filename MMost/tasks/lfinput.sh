#!/bin/bash
source /root/MMost/vars.sh

init_script

perl_inside='use HTTP::Date;$c=0; while(<STDIN>){if(/(\S+\s+){4}(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2})\s+(.+)/) {$timestamp=str2time($3); $now=time(); $d=($now-$timestamp);if($d>100){$c++;$size=int($2/1024);$dtim=$3;$file=$4;}}} $s=":white_check_mark:"; if($c>0){$s=":warning:";} if($c>3){$s=":red_circle:";} print "$s Total files: $c"; if($c>0){print "\nOldest file: \`$file\`, $size KB, from $dtim\n";}'

remote_command='for dr in /index_hd/usr/local/elm/input/compressed_lfinput /usr/local/elm/input/compressed_lfinput ; do if [ -d $dr ] ; then ls -Albt --time-style=long-iso $dr | tail -n +2 | perl -e '"'"$perl_inside"'"' ; fi ; done'

while IFS= read -r LINE
do
	if [[ $LINE =~ $LINE_REGEX ]] ; then
		NAME=${BASH_REMATCH[1]}
		IP=${BASH_REMATCH[2]}
		TYPE=${BASH_REMATCH[3]}

		if [[ $TYPE == "ELM" || $TYPE == "ELMREC" ]] ; then
			do_ssh $IP $NAME $INTERIM_FILE "$remote_command"
		fi
	fi
done < "$DEVICES"

sort -k2 -b -u < $INTERIM_FILE >> $OUTPUT_FILE

template="NEUTRAL"

#MMOST_CHANNEL='vixieali-test'

${MMOST_SENDER} --channel $MMOST_CHANNEL --mmost-webhook $MMOST_HOOK --use-template $template --username "`/bin/date` ... $HOST_NAME ... $0" --title "Is compressed_lfinput empty?" < $OUTPUT_FILE

cleanup_script


## PREDELAT: ls musi byt uvnitr perloveho skriptu, abych se z toho nepodelala. Pajpou predavat jmena adresaru, ve kterych by mohl byt compressed_lfinput. Opruz je v predavani HOSTNAME uvnitr cyklu.