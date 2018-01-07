#!/usr/bin/env bash
#
# Upload file(s) to FTP server
#
# Copyright (C) 2016 - 2018 Teddysun <i@teddysun.com>
#
# Argument example:
# 1) ./ftp_upload.sh filename
# 2) ./ftp_upload.sh filename1 filename2 filename3 ...
# 3) ./ftp_upload.sh "*.extension"
# 4) ./ftp_upload.sh "*.extension1" "*.extension2"
#

########## START OF CONFIG ##########

# Local directory (current folder)
LOCALDIR=$( pwd )

# File to log the outcome of backups
LOGFILE="/var/log/ftp_upload.log"

# FTP server
# Enter the Hostname or IP address below
FTP_HOST=""

# FTP username
# Enter the FTP username below
FTP_USER=""

# FTP password
# Enter the username's password below
FTP_PASS=""

# FTP server remote folder
# Enter the FTP remote folder below
# For example: public_html
FTP_DIR=""

########## END OF CONFIG ##########


log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1"
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}

# Check ftp command
check_command() {
    if [ ! "$(command -v "ftp")" ]; then
        log "ftp command is not installed, please install it and try again"
        exit 1
    fi
}

# Tranferring backup file to FTP server
ftp_upload() {
    cd ${LOCALDIR} || exit

    [ -z ${FTP_HOST} ] && log "Error: FTP_HOST can not be empty!" && exit 1
    [ -z ${FTP_USER} ] && log "Error: FTP_USER can not be empty!" && exit 1
    [ -z ${FTP_PASS} ] && log "Error: FTP_PASS can not be empty!" && exit 1
    [ -z ${FTP_DIR} ] && log "Error: FTP_DIR can not be empty!" && exit 1

    echo "$@" | grep "*" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        ls $@ > /dev/null 2>&1
        [ $? -ne 0 ] && log "Error: [$@] file(s) not exists!" && exit 1
    else
        for f in $@
        do
            [ ! -f ${f} ] && log "Error: [${f}] not exists!" && exit 1
        done
    fi

    local FTP_OUT_FILE=("$@")

    log "Tranferring file(s) list below to FTP server:"
    for file in ${FTP_OUT_FILE[@]}
    do
        log "$file"
    done
    ftp -in ${FTP_HOST} 2>&1 >> ${LOGFILE} <<EOF
user $FTP_USER $FTP_PASS
binary
lcd $LOCALDIR
cd $FTP_DIR
mput ${FTP_OUT_FILE[@]}
quit
EOF
    log "Tranfer to FTP server completed"
}


# Main progress
STARTTIME=$(date +%s)

[ $# -eq 0 ] && log "Error: argument can not be empty!" && exit 1

check_command

ftp_upload "$@"


ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Transfer completed in ${DURATION} seconds"
