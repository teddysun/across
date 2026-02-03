#!/usr/bin/env bash
#
# Upload file(s) to FTP server
#
# Copyright (C) 2016 - 2026 Teddysun <i@teddysun.com>
#
# Argument example:
# 1) ./ftp_upload.sh filename
# 2) ./ftp_upload.sh filename1 filename2 filename3 ...
# 3) ./ftp_upload.sh "*.extension"
# 4) ./ftp_upload.sh "*.extension1" "*.extension2"
#

########## START OF CONFIG ##########

# Local directory (current folder)
LOCALDIR=$(pwd)

# File to log the outcome of uploads
readonly LOGFILE="/var/log/ftp_upload.log"

# FTP server
# Enter the Hostname or IP address below
readonly FTP_HOST=""

# FTP username
# Enter the FTP username below
readonly FTP_USER=""

# FTP password
# Enter the username's password below
readonly FTP_PASS=""

# FTP server remote folder
# Enter the FTP remote folder below
# For example: public_html
readonly FTP_DIR=""

########## END OF CONFIG ##########


log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1"
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}

# Check ftp command
check_command() {
    if [ ! "$(command -v "ftp")" ]; then
        log "The ftp command is not installed, please install it and try again"
        exit 1
    fi
}

# Transferring file(s) to FTP server
ftp_upload() {
    cd "${LOCALDIR}" || exit 2

    [ -z "${FTP_HOST}" ] && log "Error: FTP_HOST can not be empty!" && exit 1
    [ -z "${FTP_USER}" ] && log "Error: FTP_USER can not be empty!" && exit 1
    [ -z "${FTP_PASS}" ] && log "Error: FTP_PASS can not be empty!" && exit 1
    [ -z "${FTP_DIR}" ] && log "Error: FTP_DIR can not be empty!" && exit 1

    # Check if files exist (handle wildcards)
    local file_count=0
    for f in "$@"; do
        if [[ "${f}" == *"*"* ]]; then
            # Wildcard pattern
            if ! ls "${f}" > /dev/null 2>&1; then
                log "Error: [${f}] no matching files found!"
                exit 3
            fi
            file_count=$((file_count + 1))
        else
            if [ ! -f "${f}" ]; then
                log "Error: [${f}] not found!"
                exit 4
            fi
            file_count=$((file_count + 1))
        fi
    done
    if [ ${file_count} -eq 0 ]; then
        log "Error: no valid file(s) found!"
        exit 5
    fi

    local FTP_OUT_FILE=("$@")

    log "Transferring file(s) list below to FTP server:"
    for file in "${FTP_OUT_FILE[@]}"
    do
        log "${file}"
    done
    ftp -in "${FTP_HOST}" 2>&1 >> ${LOGFILE} <<EOF
user ${FTP_USER} ${FTP_PASS}
binary
lcd ${LOCALDIR}
cd ${FTP_DIR}
mput ${FTP_OUT_FILE[@]}
quit
EOF
    log "Transfer to FTP server completed"
}

# Main process
STARTTIME=$(date +%s)

[ $# -eq 0 ] && log "Error: argument(s) cannot be empty!" && exit 1

check_command

ftp_upload "$@"

ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Transfer completed in ${DURATION} seconds"
