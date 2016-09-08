#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
#==============================================================#
#   Description: backup script                                 #
#   Author: Teddysun <i@teddysun.com>                          #
#   Visit:  https://teddysun.com                               #
#==============================================================#

[[ $EUID -ne 0 ]] && echo 'Error: This script must be run as root!' && exit 1

### START OF CONFIG ###
# Encrypt flag(true:encrypt, false:not encrypt)
ENCRYPTFLG=true

# KEEP THE PASSWORD SAFE.
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

# OPTIONAL: If you want MySQL to be backed up, enter the root password below
MYSQL_ROOT_PASSWORD=""

# Below is a list of MySQL database name that will be backed up
# if you want backup all databases, leave it blank.
MYSQL_DATABASE_NAME[0]=""

# Below is a list of files and directories that will be backed up in the tar backup
# For example:
# File: /data/www/default/test.tgz
# Directory: /data/www/default/test/
# if you want not to be backed up, leave it blank.
BACKUP[0]=""

# Number of days to store daily local backups
LOCALAGEDAILIES="7"

# Delete Googole Drive's remote file flag(true:delete, false:not delete)
DELETE_REMOTE_FILE_FLG=true

# Date & Time
BACKUPDATE=$(date +%Y%m%d%H%M%S)

# Backup file name
TARFILE="${LOCALDIR}""$(hostname)"_"${BACKUPDATE}".tgz

# Backup MySQL dump file name
SQLFILE="${TEMPDIR}mysql_${BACKUPDATE}.sql"

### END OF CONFIG ###


log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1"
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> ${LOGFILE}
}


### START OF CHECKS ###
# Check if the backup folders exist and are writeable
if [ ! -d "${LOCALDIR}" ]; then
    mkdir -p ${LOCALDIR}
fi
if [ ! -d "${TEMPDIR}" ]; then
    mkdir -p ${TEMPDIR}
fi

# This section checks for all of the binaries used in the backup
BINARIES=( cat cd du date dirname echo openssl mysql mysqldump pwd rm tar )

# Iterate over the list of binaries, and if one isn't found, abort
for BINARY in "${BINARIES[@]}"; do
    if [ ! "$(command -v "$BINARY")" ]; then
        log "$BINARY is not installed. Install it and try again"
        exit 1
    fi
done
### END OF CHECKS ###

STARTTIME=$(date +%s)
cd ${LOCALDIR} || exit
log "Backup progress start"


### START OF MYSQL BACKUP ###
if [ -z ${MYSQL_ROOT_PASSWORD} ]; then
    log "MySQL root password not set, MySQL back up skip"
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
### END OF MYSQL BACKUP ###


### START OF TAR BACKUP ###
log "Tar backup file start"
tar -zcPf ${TARFILE} ${BACKUP[*]}
if [ $? -ne 0 ]; then
    log "Tar backup file failed"
    exit 1
fi
log "Tar backup file completed"

# Encrypt tar file
if ${ENCRYPTFLG}; then
    log "Encrypt backup file start"
    openssl enc -aes256 -in "${TARFILE}" -out "${TARFILE}.enc" -pass pass:"${BACKUPPASS}" -md sha1
    log "Encrypt backup file completed"

    # Delete unencrypted tar
    log "Delete unencrypted tar file"
    rm -f ${TARFILE}
fi

# Delete MySQL temporary dump file
log "Delete MySQL temporary dump file"
rm -f ${TEMPDIR}*.sql

log "Backup progress complete"

if ${ENCRYPTFLG}; then
    BACKUPSIZE=$(du -h ${TARFILE}.enc | cut -f1)
    log "File name: ${TARFILE}.enc, File size: ${BACKUPSIZE}"
else
    BACKUPSIZE=$(du -h ${TARFILE} | cut -f1)
    log "File name: ${TARFILE}, File size: ${BACKUPSIZE}"
fi

# Transfer backup file to Google Drive
# If you want to install gdrive command, please visit website:
# https://github.com/prasmussen/gdrive
# of cause, you can use below command to install it
# For x86_64: wget -O /usr/bin/gdrive http://dl.teddysun.com/files/gdrive-linux-x64; chmod +x /usr/bin/gdrive
# For i386: wget -O /usr/bin/gdrive http://dl.teddysun.com/files/gdrive-linux-386; chmod +x /usr/bin/gdrive

if [ ! "$(command -v "gdrive")" ]; then
    GDRIVE_COMMAND=false
    log "gdrive is not installed"
    log "File transfer skipped. please install it and try again"
else
    GDRIVE_COMMAND=true
    log "Tranferring backup file to Google Drive"
    if ${ENCRYPTFLG}; then
        gdrive upload --no-progress ${TARFILE}.enc >> ${LOGFILE}
    else
        gdrive upload --no-progress ${TARFILE} >> ${LOGFILE}
    fi
    log "Tranfer completed"
fi
### END OF TAR BACKUP ###


### START OF DELETE OLD BACKUP FILE###
getFileDate() {
    unset FILEYEAR FILEMONTH FILEDAY FILETIME FILEDAYS FILEAGE
    FILEYEAR=$(echo "$1" | cut -d_ -f2 | cut -c 1-4)
    FILEMONTH=$(echo "$1" | cut -d_ -f2 | cut -c 5-6)
    FILEDAY=$(echo "$1" | cut -d_ -f2 | cut -c 7-8)
    FILETIME=$(echo "$1" | cut -d_ -f2 | cut -c 9-14)

    if [[ "${FILEYEAR}" && "${FILEMONTH}" && "${FILEDAY}" && "${FILETIME}" ]]; then
        #Approximate a 30-day month and 365-day year
        FILEDAYS=$(( $((10#${FILEYEAR}*365)) + $((10#${FILEMONTH}*30)) + $((10#${FILEDAY})) ))
        FILEAGE=$(( 10#${DAYS} - 10#${FILEDAYS} ))
        return 0
    fi

    return 1
}

deleteRemoteFile() {
    local FILENAME=$1
    if ${DELETE_REMOTE_FILE_FLG} && ${GDRIVE_COMMAND}; then
        local FILEID=$(gdrive list -q "name = '${FILENAME}'" --no-header | awk '{print $1}')
        if [ -n ${FILEID} ]; then
            gdrive delete ${FILEID} >> ${LOGFILE}
            log "Google Drive's old backup file name:${FILENAME} has been deleted"
        fi
    fi
}

AGEDAILIES=${LOCALAGEDAILIES}
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%C%y)
#Approximate a 30-day month and 365-day year
DAYS=$(( $((10#${YEAR}*365)) + $((10#${MONTH}*30)) + $((10#${DAY})) ))

cd ${LOCALDIR} || exit

if ${ENCRYPTFLG}; then
    LS=($(ls *.enc))
else
    LS=($(ls *.tgz))
fi

for f in ${LS[*]}
do
    getFileDate ${f}
    if [ $? == 0 ]; then
        if [[ ${FILEAGE} -gt ${AGEDAILIES} ]]; then
            rm -f ${f}
            log "Old backup file name:${f} has been deleted"
            deleteRemoteFile ${f}
        fi
    fi
done
### END OF DELETE OLD BACKUP FILE###


ENDTIME=$(date +%s)
DURATION=$((ENDTIME - STARTTIME))
log "All done"
log "Backup and transfer completed in ${DURATION} seconds"
