#!/bin/bash
# chkconfig: 2345 90 10
# description: A secure socks5 proxy, designed to protect your Internet traffic.

### BEGIN INIT INFO
# Provides:          KMS Emulator
# Required-Start:    $network $syslog
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Build yourself KMS Server
# Description:       Start or stop the KMS Server
### END INIT INFO

# Author: Teddysun <i@teddysun.com>

# Source function library
. /etc/rc.d/init.d/functions

# Check that networking is up.
[ ${NETWORKING} ="yes" ] || exit 0

NAME="KMS Server"
DAEMON=/usr/bin/vlmcsd
PID_DIR=/var/run
PID_FILE=$PID_DIR/vlmcsd.pid
LOG_DIR=/var/log
LOG_FILE=$LOG_DIR/vlmcsd.log
RET_VAL=0

[ -x $DAEMON ] || exit 0

if [ ! -d $PID_DIR ]; then
    mkdir -p $PID_DIR
    if [ $? -ne 0 ]; then
        echo "Creating PID directory $PID_DIR failed"
        exit 1
    fi
fi

if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
    if [ $? -ne 0 ]; then
        echo "Creating LOG directory $LOG_DIR failed"
        exit 1
    fi
fi

check_running() {
    if [ -r $PID_FILE ]; then
        read PID < $PID_FILE
        if [ -d "/proc/$PID" ]; then
            return 0
        else
            rm -f $PID_FILE
            return 1
        fi
    else
        return 2
    fi
}

do_status() {
    check_running
    case $? in
        0)
        echo "$NAME (pid $PID) is running..."
        ;;
        1|2)
        echo "$NAME is stopped"
        RET_VAL=1
        ;;
    esac
}

do_start() {
    if check_running; then
        echo "$NAME (pid $PID) is already running..."
        return 0
    fi
    $DAEMON -p $PID_FILE -l $LOG_FILE
    sleep 0.3
    if check_running; then
        echo "Starting $NAME success"
    else
        echo "Starting $NAME failed"
        RET_VAL=1
    fi
}

do_stop() {
    if check_running; then
        kill -9 $PID
        rm -f $PID_FILE
        echo "Stopping $NAME success"
    else
        echo "$NAME is stopped"
        RET_VAL=1
    fi
}

do_restart() {
    do_stop
    do_start
}

case "$1" in
    start|stop|restart|status)
    do_$1
    ;;
    *)
    echo "Usage: $0 { start | stop | restart | status }"
    RET_VAL=1
    ;;
esac

exit $RET_VAL
