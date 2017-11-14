#!/usr/bin/env bash
#
# Auto backup script
#
# Copyright (C) 2016 Teddysun <i@teddysun.com>
#
# URL: https://teddysun.com/469.html
#
# You must to modify the config before run it!!!
# Backup MySQL/MariaDB/Percona datebases, files and directories
# Backup file is encrypted with AES256-cbc with SHA1 message-digest (option)
# Auto transfer backup file to Google Drive (need install gdrive command) (option)
# Auto transfer backup file to FTP server (option)
# Auto delete Google Drive's or FTP server's remote file (option)
#

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

########## START OF CONFIG ##########

# Encrypt flag (true: encrypt, false: not encrypt)
ENCRYPTFLG=true

# WARNING: KEEP THE PASSWORD SAFE!!!
# The password used to encrypt the backup
# To decrypt backups made by this script, run the following command:
# openssl enc -aes256 -in [encrypted backup] -out decrypted_backup.tgz -pass pass:[backup password] -d -md sha1
BACKUPPASS="mypassword"

# Directory to store backups
LOCALDIR="/root/backups/"

# Temporary directory used during backup creation
TEMPDIR="/root/backups/temp/"

# File to log the outcome of backups
LOGFILE="/root/backups/backup.log"

# OPTIONAL: If you want backup MySQL database, enter the MySQL root password below
MYSQL_ROOT_PASSWORD=""

# Below is a list of MySQL database name that will be backed up
# If you want backup ALL databases, leave it blank.
MYSQL_DATABASE_NAME[0]=""

# Below is a list of files and directories that will be backed up in the tar backup
# For example:
# File: /data/www/default/test.tgz
# Directory: /data/www/default/test
BACKUP[0]=""

# Number of days to store daily local backups (default 7 days)
LOCALAGEDAILIES="7"

# Delete Googole Drive's & FTP server's remote file flag (true: delete, false: not delete)
DELETE_REMOTE_FILE_FLG=false

# Upload to FTP server flag (true: upload, false: not upload)
FTP_FLG=false

# FTP server
# OPTIONAL: If you want upload to FTP server, enter the Hostname or IP address below
FTP_HOST=""

# FTP username
# OPTIONAL: If you want upload to FTP server, enter the FTP username below
FTP_USER=""

# FTP password
# OPTIONAL: If you want upload to FTP server, enter the username's password below
FTP_PASS=""

# FTP server remote folder
# OPTIONAL: If you want upload to FTP server, enter the FTP remote folder below
# For example: public_html
FTP_DIR=""

########## END OF CONFIG ##########



# Date & Time
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%C%y)
BACKUPDATE=$(date +%Y%m%d%H%M%S)
# Backup file name
TARFILE="${LOCALDIR}""$(hostname)"_"${BACKUPDATE}".tgz
# Encrypted backup file name
ENC_TARFILE="${TARFILE}.enc"
# Backup MySQL dump file name
SQLFILE="${TEMPDIR}mysql_${BACKUPDATE}.sql"

log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1"
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}

# Check for list of mandatory binaries
check_commands() {
    # This section checks for all of the binaries used in the backup
    BINARIES=( cat cd du date dirname echo openssl mysql mysqldump pwd rm tar )
    
    # Iterate over the list of binaries, and if one isn't found, abort
    for BINARY in "${BINARIES[@]}"; do
        if [ ! "$(command -v "$BINARY")" ]; then
            log "$BINARY is not installed. Install it and try again"
            exit 1
        fi
    done

    # check gdrive command
    GDRIVE_COMMAND=false
    if [ "$(command -v "gdrive")" ]; then
        GDRIVE_COMMAND=true
    fi

    # check ftp command
    if ${FTP_FLG}; then
        if [ ! "$(command -v "ftp")" ]; then
            log "ftp is not installed. Install it and try again"
            exit 1
        fi
    fi
}

calculate_size() {
    local file_name=$1
    local file_size=$(du -h $file_name 2>/dev/null | awk '{print $1}')
    if [ "x${file_size}" = "x" ]; then
        echo "unknown"
    else
        echo "${file_size}"
    fi
}

# Backup MySQL databases
mysql_backup() {
    if [ -z ${MYSQL_ROOT_PASSWORD} ]; then
        log "MySQL root password not set, MySQL backup skipped"
    else
        log "MySQL dump start"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null <<EOF
exit
EOF
        if [ $? -ne 0 ]; then
            log "MySQL root password is incorrect. Please check it and try again"
            exit 1
        fi
    
        if [ "${MYSQL_DATABASE_NAME[*]}" == "" ]; then
            mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases > "${SQLFILE}" 2>/dev/null
            if [ $? -ne 0 ]; then
                log "MySQL all databases backup failed"
                exit 1
            fi
            log "MySQL all databases dump file name: ${SQLFILE}"
            #Add MySQL backup dump file to BACKUP list
            BACKUP=(${BACKUP[*]} ${SQLFILE})
        else
            for db in ${MYSQL_DATABASE_NAME[*]}
            do
                unset DBFILE
                DBFILE="${TEMPDIR}${db}_${BACKUPDATE}.sql"
                mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" ${db} > "${DBFILE}" 2>/dev/null
                if [ $? -ne 0 ]; then
                    log "MySQL database name [${db}] backup failed, please check database name is correct and try again"
                    exit 1
                fi
                log "MySQL database name [${db}] dump file name: ${DBFILE}"
                #Add MySQL backup dump file to BACKUP list
                BACKUP=(${BACKUP[*]} ${DBFILE})
            done
        fi
        log "MySQL dump completed"
    fi
}

start_backup() {
    [ "${BACKUP[*]}" == "" ] && echo "Error: You must to modify the [$(basename $0)] config before run it!" && exit 1

    log "Tar backup file start"
    tar -zcPf ${TARFILE} ${BACKUP[*]}
    if [ $? -gt 1 ]; then
        log "Tar backup file failed"
        exit 1
    fi
    log "Tar backup file completed"

    # Encrypt tar file
    if ${ENCRYPTFLG}; then
        log "Encrypt backup file start"
        openssl enc -aes256 -in "${TARFILE}" -out "${ENC_TARFILE}" -pass pass:"${BACKUPPASS}" -md sha1
        log "Encrypt backup file completed"

        # Delete unencrypted tar
        log "Delete unencrypted tar file: ${TARFILE}"
        rm -f ${TARFILE}
    fi

    # Delete MySQL temporary dump file
    for sql in `ls ${TEMPDIR}*.sql`
    do
        log "Delete MySQL temporary dump file: ${sql}"
        rm -f ${sql}
    done

    if ${ENCRYPTFLG}; then
        OUT_FILE="${ENC_TARFILE}"
    else
        OUT_FILE="${TARFILE}"
    fi
    log "File name: ${OUT_FILE}, File size: `calculate_size ${OUT_FILE}`"
}

# Transfer backup file to Google Drive
# If you want to install gdrive command, please visit website:
# https://github.com/prasmussen/gdrive
# of cause, you can use below command to install it
# For x86_64: wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-x64; chmod +x /usr/bin/gdrive
# For i386: wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-386; chmod +x /usr/bin/gdrive
gdrive_upload() {
    if ${GDRIVE_COMMAND}; then
        log "Tranferring backup file to Google Drive"
        gdrive upload --no-progress ${OUT_FILE} >> ${LOGFILE}
        if [ $? -ne 0 ]; then
            log "Error: Tranferring backup file to Google Drive failed"
            exit 1
        fi
        log "Tranferring backup file to Google Drive completed"
    fi
}

# Tranferring backup file to FTP server
ftp_upload() {
    if ${FTP_FLG}; then
        [ -z ${FTP_HOST} ] && log "Error: FTP_HOST can not be empty!" && exit 1
        [ -z ${FTP_USER} ] && log "Error: FTP_USER can not be empty!" && exit 1
        [ -z ${FTP_PASS} ] && log "Error: FTP_PASS can not be empty!" && exit 1
        [ -z ${FTP_DIR} ] && log "Error: FTP_DIR can not be empty!" && exit 1

        local FTP_OUT_FILE=$(basename ${OUT_FILE})
        log "Tranferring backup file to FTP server"
        ftp -in ${FTP_HOST} 2>&1 >> ${LOGFILE} <<EOF
user $FTP_USER $FTP_PASS
binary
lcd $LOCALDIR
cd $FTP_DIR
put $FTP_OUT_FILE
quit
EOF
        log "Tranferring backup file to FTP server completed"
    fi
}

# Get file date
get_file_date() {
    #Approximate a 30-day month and 365-day year
    DAYS=$(( $((10#${YEAR}*365)) + $((10#${MONTH}*30)) + $((10#${DAY})) ))

    unset FILEYEAR FILEMONTH FILEDAY FILEDAYS FILEAGE
    FILEYEAR=$(echo "$1" | cut -d_ -f2 | cut -c 1-4)
    FILEMONTH=$(echo "$1" | cut -d_ -f2 | cut -c 5-6)
    FILEDAY=$(echo "$1" | cut -d_ -f2 | cut -c 7-8)

    if [[ "${FILEYEAR}" && "${FILEMONTH}" && "${FILEDAY}" ]]; then
        #Approximate a 30-day month and 365-day year
        FILEDAYS=$(( $((10#${FILEYEAR}*365)) + $((10#${FILEMONTH}*30)) + $((10#${FILEDAY})) ))
        FILEAGE=$(( 10#${DAYS} - 10#${FILEDAYS} ))
        return 0
    fi

    return 1
}

# Delete Google Drive's old backup file
delete_gdrive_file() {
    local FILENAME=$1
    if ${DELETE_REMOTE_FILE_FLG} && ${GDRIVE_COMMAND}; then
        local FILEID=$(gdrive list -q "name = '${FILENAME}'" --no-header | awk '{print $1}')
        if [ -n ${FILEID} ]; then
            gdrive delete ${FILEID} >> ${LOGFILE}
            log "Google Drive's old backup file name: ${FILENAME} has been deleted"
        fi
    fi
}

# Delete FTP server's old backup file
delete_ftp_file() {
    local FILENAME=$1
    if ${DELETE_REMOTE_FILE_FLG} && ${FTP_FLG}; then
        ftp -in ${FTP_HOST} 2>&1 >> ${LOGFILE} <<EOF
user $FTP_USER $FTP_PASS
cd $FTP_DIR
del $FILENAME
quit
EOF
        log "FTP server's old backup file name: ${FILENAME} has been deleted"
    fi
}

# Clean up old file
clean_up_files() {
    cd ${LOCALDIR} || exit

    if ${ENCRYPTFLG}; then
        LS=($(ls *.enc))
    else
        LS=($(ls *.tgz))
    fi

    for f in ${LS[@]}
    do
        get_file_date ${f}
        if [ $? == 0 ]; then
            if [[ ${FILEAGE} -gt ${LOCALAGEDAILIES} ]]; then
                rm -f ${f}
                log "Old backup file name: ${f} has been deleted"
                delete_gdrive_file ${f}
                delete_ftp_file ${f}
            fi
        fi
    done
}

# Main progress
STARTTIME=$(date +%s)

# Check if the backup folders exist and are writeable
if [ ! -d "${LOCALDIR}" ]; then
    mkdir -p ${LOCALDIR}
fi
if [ ! -d "${TEMPDIR}" ]; then
    mkdir -p ${TEMPDIR}
fi

log "Backup progress start"
check_commands
mysql_backup
start_backup
log "Backup progress complete"

log "Upload progress start"
gdrive_upload
ftp_upload
log "Upload progress complete"

clean_up_files

ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Backup and transfer completed in ${DURATION} seconds"
