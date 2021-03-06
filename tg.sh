#!/bin/bash

# Enable debug mode to see what we send to Telegram
set -x

# Static link to targets health checks
HEALTH_URL="https://itarmy.com.ua/check/"

# Save large output to a file
LOGS=$(pwd)/mhddos.log

# Get average statistic for the last 15 mins
LOGS_15=$(sed -n "/$(date --date='15 minutes ago' +%R:)/,\$p" $LOGS)
if [ -z "$LOGS_15" ]; then
    CAPACITY_15='n/a'
    CONNECTIONS_15='n/a'
    PACKETS_15='n/a'
    TRAFFIC_15='n/a'
else
    CAPACITY_15=$(echo "scale=1; $(echo "$LOGS_15" | grep -o "Capacity.*%" | cut -d' ' -f2 | sed s/%//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_15" | grep -o "Capacity.*%" | wc -l)" | bc)
    CONNECTIONS_15=$(echo "scale=0; $(echo "$LOGS_15" | grep -oE "Connections: [0-9]*," | cut -d' ' -f2 | sed s/,//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_15" | grep -oE "Connections: [0-9]*," | wc -l)" | bc)
    PACKETS_15=$(echo "scale=1; $(echo "$LOGS_15" | grep -oE "Packets: [0-9.]*k" | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_15" | grep -oE "Packets: [0-9.]*k" | wc -l)" | bc)
    TRAFFIC_15=$(echo "scale=1; $(echo "$LOGS_15" | grep -oE "Traffic: [0-9.]* MBit" | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_15" | grep -oE "Traffic: [0-9.]* MBit" | wc -l)" | bc)
fi

# Get average statistic for the last 60 mins
LOGS_60=$(sed -n "/$(date --date='60 minutes ago' +%R:)/,\$p" $LOGS)
if [ -z "$LOGS_60" ]; then
    CAPACITY_60='n/a'
    CONNECTIONS_60='n/a'
    PACKETS_60='n/a'
    TRAFFIC_60='n/a'
else
    CAPACITY_60=$(echo "scale=1; $(echo "$LOGS_60" | grep -o "Capacity.*%" | cut -d' ' -f2 | sed s/%//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_60" | grep -o "Capacity.*%" | wc -l)" | bc)
    CONNECTIONS_60=$(echo "scale=0; $(echo "$LOGS_60" | grep -oE "Connections: [0-9]*," | cut -d' ' -f2 | sed s/,//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_60" | grep -oE "Connections: [0-9]*," | wc -l)" | bc)
    PACKETS_60=$(echo "scale=1; $(echo "$LOGS_60" | grep -oE "Packets: [0-9.]*k" | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_60" | grep -oE "Packets: [0-9.]*k" | wc -l)" | bc)
    TRAFFIC_60=$(echo "scale=1; $(echo "$LOGS_60" | grep -oE "Traffic: [0-9.]* MBit" | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(echo "$LOGS_60" | grep -oE "Traffic: [0-9.]* MBit" | wc -l)" | bc)
fi

# Get average statistic for the all time
CAPACITY_ALL=$(echo "scale=1; $(grep -o "Capacity.*%" $LOGS | cut -d' ' -f2 | sed s/%//g | xargs  | sed -e 's/\ /+/g' | bc)/$(grep -o "Capacity.*%" $LOGS| wc -l)" | bc)
CONNECTIONS_ALL=$(echo "scale=0; $(grep -oE "Connections: [0-9]*," $LOGS | cut -d' ' -f2 | sed s/,//g | xargs  | sed -e 's/\ /+/g' | bc)/$(grep -oE "Connections: [0-9]*," $LOGS | wc -l)" | bc)
PACKETS_ALL=$(echo "scale=1; $(grep -oE "Packets: [0-9.]*k" $LOGS | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(grep -oE "Packets: [0-9.]*k" $LOGS | wc -l)" | bc)
TRAFFIC_ALL=$(echo "scale=1; $(grep -oE "Traffic: [0-9.]* MBit" $LOGS | cut -d' ' -f2 | sed s/k//g | xargs  | sed -e 's/\ /+/g' | bc)/$(grep -oE "Traffic: [0-9.]* MBit" $LOGS | wc -l)" | bc)

# Create table with statistic
STATS=$(cat <<-END
|15m|60m|All
|---|---|---
????????????????????, %|$CAPACITY_15|$CAPACITY_60|$CAPACITY_ALL
??'????????????|$CONNECTIONS_15|$CONNECTIONS_60|$CONNECTIONS_ALL
????????????, k/s|$PACKETS_15|$PACKETS_60|$PACKETS_ALL
????????????, M/s|$TRAFFIC_15|$TRAFFIC_60|$TRAFFIC_ALL
END
)
TABLE=$(echo "$STATS" | column -t -n -s'|')

#Get date start attack
STARTATTACK=$(sed -n "8p" $LOGS | cut -c 2-9)

#Get version mhddos
VERSION=$(sed -n "8p" $LOGS | cut -c 48-51)

# Get number of threads
THREADS=$(grep -o Threads.* $LOGS| tail -n 1 | cut -d' ' -f 2)

# Compose a message
message="*????????*: \`\`\`$(hostname)\`\`\`"
message+="%0A"
message+="*??????????????*: \`\`\`$THREADS\`\`\`"
message+="%0A"
message+="*????????????*: \`\`\`$VERSION\`\`\`"
message+="%0A"
message+="*???????????? ???????????????? ??*: \`\`\`$STARTATTACK\`\`\`"
message+="%0A"
message+=$(cat <<-END
\`\`\`
$TABLE
\`\`\`
END
)

# Generate a button link to targets health report
keyboard="{\"inline_keyboard\":[[{\"text\":\"???????????????? ???????? ?????? ???????? ??????????\", \"url\":\"${HEALTH_URL}\"}]]}"

# Send to Telegram
curl -s --data "text=${message}" \
        --data "reply_markup=${keyboard}" \
        --data "chat_id=$TG_CHAT_ID" \
        --data "parse_mode=markdown" \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"