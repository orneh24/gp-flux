#! /bin/bash
# Generate random amount of Bacon Ipsum files of varying sizes and syslog them
BACON_DL_COUNT="$(( $RANDOM % 250 + 50 ))"
BACON_DL_URL="https://baconipsum.com/api/?type=meat-and-filler&format=text&paras="
SYSLOG_SERVER="8.8.4.4"

for (( i=0; i<$BACON_DL_COUNT; ++i)); do
    wget "https://baconipsum.com/api/?type=meat-and-filler&format=text&paras=$(( $RANDOM % 50 + 5 ))" -P downloads/wget_baconipsum/
    sleep 1
done
BACON_SYSLOG_FILES=(downloads/wget_baconipsum/*)
for i in "${BACON_SYSLOG_FILES[@]}"; do logger --file $i --server 8.8.8.8; done