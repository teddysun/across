#!/bin/sh
# IPsec startup and shutdown script
#
### BEGIN INIT INFO
# Provides: ipsec
# Required-Start: $network $remote_fs $syslog $named
# Required-Stop: $syslog $remote_fs
# Default-Start: 
# Default-Stop: 0 1 6
# Short-Description: Start Libreswan IPsec at boot time
# Description: Enable automatic key management for IPsec (KLIPS and NETKEY)
### END INIT INFO
#
### see https://bugzilla.redhat.com/show_bug.cgi?id=636572
### Debian and Fedora interpret the LSB differently for Default-Start:

# Copyright (C) 1998, 1999, 2001  Henry Spencer.
# Copyright (C) 2002              Michael Richardson <mcr@freeswan.org>
# Copyright (C) 2006              Michael Richardson <mcr@xelerance.com>
# Copyright (C) 2008              Michael Richardson <mcr@sandelman.ca>
# Copyright (C) 2008-2015         Tuomo Soini <tis@foobar.fi>
# Copyright (C) 2012              Paul Wouters <paul@libreswan.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <https://www.gnu.org/licenses/gpl2.txt>.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# ipsec		sysv style init.d script for starting and stopping
#		the IPsec security subsystem (KLIPS and Pluto).
#
# This script becomes /etc/init.d/ipsec
# and is also accessible as "ipsec setup"
#
# The startup and shutdown times are a difficult compromise (in particular,
# it is almost impossible to reconcile them with the insanely early/late
# times of NFS filesystem startup/shutdown).  Startup is after startup of
# syslog and pcmcia support; shutdown is just before shutdown of syslog.
#
# chkconfig: - 47 76
# description: IPsec provides encrypted and authenticated communications; \
# NETKEY/KLIPS is the kernel half of it, Pluto is the user-level management daemon.

test ${IPSEC_INIT_SCRIPT_DEBUG} && set -v -x

# Source function library.
if [ -f /etc/init.d/functions ]; then
    . /etc/init.d/functions
elif [ -f /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
fi

# Check that networking is up.
[ "${NETWORKING}" = "no" ] && exit 6

if [ $(id -u) -ne 0 ]; then
    echo "permission denied (must be superuser)" | \
	logger -s -p daemon.error -t ipsec_setup 2>&1
    exit 4
fi

if [ $(ip addr list | grep -c cipsec) -ne 0 ]; then
    echo "Cisco IPsec client is already loaded, aborting! (cipsec# device found)"
    exit 1
fi

# where the private directory and the config files are
IPSEC_CONF="${IPSEC_CONF:-/etc/ipsec.conf}"
IPSEC_EXECDIR="${IPSEC_EXECDIR:-/usr/libexec/ipsec}"
IPSEC_SBINDIR="${IPSEC_SBINDIR:-/usr/sbin}"
unset PLUTO_OPTIONS

rundir=/run/pluto
plutopid=${rundir}/pluto.pid
plutoctl=${rundir}/pluto.ctl
lockdir=/var/lock/subsys
lockfile=${lockdir}/ipsec

# /etc/resolv.conf related paths
LIBRESWAN_RESOLV_CONF=${rundir}/libreswan-resolv-conf-backup
ORIG_RESOLV_CONF=/etc/resolv.conf

# there is some confusion over the name - just do both
[ -f /etc/sysconfig/ipsec ] && . /etc/sysconfig/ipsec
[ -f /etc/sysconfig/pluto ] && . /etc/sysconfig/pluto

# misc setup
umask 022

# standardize PATH, and export it for everything else's benefit
PATH="${IPSEC_SBINDIR}:/sbin:/usr/sbin:/usr/local/bin:/bin:/usr/bin"
export PATH

mkdir -p ${rundir}
chmod 700 ${rundir}

verify_config() {
    [ -f ${IPSEC_CONF} ] || exit 6

    config_error=$(ipsec addconn --config ${IPSEC_CONF} --checkconfig 2>&1)
    RETVAL=$?
    if [ ${RETVAL} -gt 0 ]; then
	echo "Configuration error - the following error occurred:"
	echo ${config_error}
	echo "IKE daemon status was not modified"
	exit ${RETVAL}
    fi
}

start() {
    echo -n "Starting pluto IKE daemon for IPsec: "
    ipsec _stackmanager start

    # pluto searches the current directory, so this is required for making it selinux compliant
    cd /
    # Create nss db or convert from old format to new sql format
    ipsec --checknss
    # Enable nflog if configured
    ipsec --checknflog > /dev/null
    # This script will enter an endless loop to ensure pluto restarts on crash
    ipsec _plutorun --config ${IPSEC_CONF} --nofork ${PLUTO_OPTIONS} &
    [ -d ${lockdir} ] || mkdir -p ${lockdir}
    touch ${lockfile}
    # Because _plutorun starts pluto at background we need to make sure pluto is started
    # before we know if start was successful or not
    for waitsec in 1 2 3 4 5; do
	if status >/dev/null; then
	    RETVAL=0
	    break
	else
	    echo -n "."
	    sleep 1
	    RETVAL=1
	fi
    done
    if [ ${RETVAL} -ge 1 ]; then
	rm -f ${lockfile}
    fi
    echo
    if [ -f /usr/libexec/ipsec/portexcludes ] ; then
	/usr/libexec/ipsec/portexcludes
    fi
    return ${RETVAL}
}


stop() {
    if [ -e ${plutoctl} ]; then
	echo "Shutting down pluto IKE daemon"
	ipsec whack --shutdown 2>/dev/null
	# don't use seq, might not exist on embedded
	for waitsec in 1 2 3 4 5 6 7 8 9 10; do
	    if [ -s ${plutopid} ]; then
		echo -n "."
		sleep 1
	    else
		break
	    fi
	done
	echo
	rm -f ${plutoctl} # we won't be using this anymore
    fi
    if [ -s ${plutopid} ]; then
	# pluto did not die peacefully
	pid=$(cat ${plutopid})
	if [ -d /proc/${pid} ]; then
	    kill -TERM ${pid}
	    RETVAL=$?
	    sleep 5;
	    if [ -d /proc/${pid} ]; then
		kill -KILL ${pid}
		RETVAL=$?
	    fi
	    if [ ${RETVAL} -ne 0 ]; then
		echo "Kill failed - removing orphaned ${plutopid}"
	    fi
	else
	    echo "Removing orphaned ${plutopid}"
	fi
	rm -f ${plutopid}
    fi

    ipsec _stackmanager stop
    ipsec --stopnflog > /dev/null

    # cleaning up backup resolv.conf
    if [ -e ${LIBRESWAN_RESOLV_CONF} ]; then
	if grep 'Libreswan' ${ORIG_RESOLV_CONF} > /dev/null 2>&1; then
	    cp ${LIBRESWAN_RESOLV_CONF} ${ORIG_RESOLV_CONF}
	fi
	rm -f  ${LIBRESWAN_RESOLV_CONF}
    fi

    rm -f ${lockfile}
    return ${RETVAL}
}

restart() {
    verify_config
    stop
    start
    return $?
}

status() {
    local RC
    if [ -f ${plutopid} ]; then
	if [ -r ${plutopid} ]; then
	    pid=$(cat ${plutopid})
	    if [ -n "$pid" -a -d /proc/${pid} ]; then
		RC=0	# running
	    else
		RC=1	# not running but pid exists
	    fi
	else
	    RC=4	# insufficient privileges
	fi
    fi
    if [ -z "${RC}" ]; then
	if [ -f ${lockfile} ]; then
	    RC=2
	else
	    RC=3
	fi
    fi
    case "${RC}" in
	0)
	    echo "ipsec: pluto (pid ${pid}) is running..."
	    return 0
	    ;;
	1)
	    echo "ipsec: pluto dead but pid file exits"
	    return 1
	    ;;
	2)
	    echo "ipsec: pluto dead but subsys locked"
	    return 2
	    ;;
	4)
	    echo "ipsec: pluto status unknown due to insufficient privileges."
	    return 4
	    ;;
    esac
    echo "ipsec: pluto is stopped"
    return 3
}

condrestart() {
    verify_config
    RETVAL=$?
    if [ -f ${lockfile} ]; then
	restart
	RETVAL=$?
    fi
    return ${RETVAL}
}

version() {
    ipsec version
    return $?
}


# do it
case "$1" in
    start)
	start
	RETVAL=$?
	;;
    stop)
	stop
	RETVAL=$?
	;;
    restart)
	restart
	RETVAL=$?
	;;
    reload|force-reload)
	restart
	RETVAL=$?
	;;
    condrestart|try-restart)
	condrestart
	RETVAL=$?
	;;
    status)
	status
	RETVAL=$?
	${IPSEC_EXECDIR}/whack --status 2>/dev/null | grep Total | sed 's/^000\ Total\ //'
	;;
    version)
	version
	RETVAL=$?
	;;
    *)
	echo "Usage: $0 {start|stop|restart|reload|force-reload|condrestart|try-restart|status|version}"
	RETVAL=2
esac

exit ${RETVAL}
