#! /bin/sh
# Checks if the internet conn is up.  If not, it tries to restart
# the network.  If that fails, then reboot.

#Host to check if is line
host=8.8.8.8
#Minimum Uptime before testing in minutes
min_uptime=15
#Logfiles temp
OK_LOG=/tmp/check_internet.log
FAIL_LOG=/tmp/check_internet_down.log
#Logfile persitant
REBOOT_LOG=/root/check_internet.log
#Lockfile
LOCK_FILE=/tmp/check_internet.lock

#if (( "$(awk '{print int($1/60)}' /proc/uptime)" < $min_uptime ))
if [ "$min_uptime" -gt "$(awk '{print int($1/60)}' /proc/uptime)" ]
then
  echo "system is not long enought up"
  exit 0
fi

if test -f "$LOCK_FILE"
then
  echo "Lock $LOCK_FILE exist"
  echo "END"
else
  touch $LOCK_FILE
  if ping -c 1 $host > /dev/null
  then
    echo "$(date)"  "Internet is up" >> $OK_LOG
    echo "$(tail -n 100 $OK_LOG)" > $OK_LOG
    echo "Internet is up"
  else
    echo "$(date)" "Internet is down try again in 1 minute" >> $FAIL_LOG
    echo "$(tail -n 100 $FAIL_LOG)" > $FAIL_LOG
    sleep 60
    if ping -c 1 $host > /dev/null
    then
      echo "$(date)"  "Internet is up after waiting 1 minute" >> $FAIL_LOG
      echo "$(tail -n 100 $FAIL_LOG)" > $FAIL_LOG
    else
      echo "$(date)"  "Internet is down - Restarting Network" >> $FAIL_LOG
      echo "$(tail -n 100 $FAIL_LOG)" > $FAIL_LOG
      /etc/init.d/network restart
      /etc/init.d/dsl_control restart
      sleep 600
      if ping -c 1 $host > /dev/null
      then
        echo "$(date)" "Internet is up after Network Restart" >> $FAIL_LOG
        echo "$(tail -n 100 $FAIL_LOG)" > $FAIL_LOG
      else
        echo "$(date)" "no more ideas - rebooting" >> $FAIL_LOG
        echo "$(tail -n 100 $FAIL_LOG)" >> $REBOOT_LOG
        echo "$(tail -n 100 $REBOOT_LOG)" > $REBOOT_LOG
        "$(/sbin/reboot -f)" >> $REBOOT_LOG
      fi
    fi
  fi
  rm $LOCK_FILE
fi

exit 0
