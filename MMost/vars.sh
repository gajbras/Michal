#!/bin/bash
DEVICES="/root/MMost/devices.txt"
TMP_DIR='/root/MMost/tmp'
TIME_STAMP=`date --utc +'%Y%m%dT%H%M%S_%N'`
OUTPUT_FILE=$TMP_DIR'/'$TIME_STAMP'_output'
INTERIM_FILE=$TMP_DIR'/'$TIME_STAMP'_interim'
#MMOST_HOOK='https://mattermost.soc.tieto.com/hooks/6heokhrapjfwzdbosw1gggfc5e' # vixieali-test
MMOST_HOOK='https://mattermost.soc.tieto.com/hooks/icja11rwqjrsfnoigncbjerf7o' # unlocked-hook
MMOST_CHANNEL='mmost-fin' # friendly channel name
HOST_NAME='SIEMFIN-ESM01'
#WEB_PROXY='-x 10.241.118.232:9090'
LINE_REGEX='\([[:digit:]]+\)[[:space:]]+(.{7}[[:graph:]]+)[[:space:]]+([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)[[:space:]]+\(([[:graph:]]+)\)'
CURL='/usr/bin/curl'
MMOST_SENDER='/root/MMost/mmost-sender/mmost-sender.pl'
# truncate file named $OUTPUT_FILE

function init_script() {
mkdir -p $TMP_DIR
: > $OUTPUT_FILE
: > $INTERIM_FILE
}

function cleanup_script() {
rm $OUTPUT_FILE
rm $INTERIM_FILE
}

function do_ssh() {
local my_ip=$1
local my_host_name=$2
local my_interim_file=$3
local my_command=$4

if [[ $my_ip == "127.0.0.1" ]] ; then
  eval $my_command $my_host_name >> $my_interim_file
else
  timeout --kill-after=30 --signal=3 20 ssh -q -n -o ConnectTimeout=5 root@$my_ip "$my_command" $my_host_name >> $my_interim_file
  local my_exit=$?
  if (($my_exit>250)) ; then
    echo ":skull_and_crossbones: \`$NAME\` Destination unreachable." >> $my_interim_file # 255 = SSH ConnectTimeout
  elif (($my_exit>123)); then
    echo ":hourglass: \`$NAME\` Task takes too long, connection terminated prematurely." >> $my_interim_file # 124 - 137 = timeout effect
  fi
fi
}
