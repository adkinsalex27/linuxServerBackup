#!/bin/bash
### Update these before running ###
PARENT_FOLDER="/path/to/folder"
SOURCE_FOLDER="${PARENT_FOLDER}/folderNameHere"

### Update the following to customize backups ###
BACKUP_INTERVAL_MINUTES=30 #how many minutes to wait between backups. Do not exceed 1 day
MAX_BACKUP_AGE_DAYS=30       # Maximum age of regular backups to retain. Daily backups will be retained indefinitely
DESTINATION_FOLDER="${PARENT_FOLDER}/backups"

# Variables to track daily backup status
daily_task_ran=false #have we ran the daily task today
last_daily_task_date="" #used to check if it's a new day since last daily task

# Function to create a backup folder
create_backup() {
    source_folder=$1
    destination_folder=$2

    # Create backup folder with current date and time appended
    backup_folder="${destination_folder}_$(date '+%Y%m%d_%H%M%S')"
    cp -r "$source_folder" "$backup_folder"

    echo "Backup created: $backup_folder"
}

# Function to delete old backups
delete_old_backups() {
    backup_folder=$1
    find "$backup_folder" -type d -mtime +"$MAX_BACKUP_AGE_DAYS" -exec rm -r {} \;
    echo "Old backups deleted."
}

# Function to check if a new day has started
check_new_day() {
    current_date=$(date '+%Y%m%d')
    if [ "$current_date" != "$last_daily_task_date" ]; then
        last_daily_task_date="$current_date"
        daily_task_ran=false
    fi
}

#make dirs if needed
mkdir -p $DESTINATION_FOLDER
mkdir -p "${DESTINATION_FOLDER}/regularBackups"
mkdir -p "${DESTINATION_FOLDER}/dailyBackups"

#create path var
regular_backup_path="${DESTINATION_FOLDER}/regularBackups/regular_backup"

# Main loop
while true; do

    # Check if it's time for a daily backup
    check_new_day
    if [ "$daily_task_ran" = false ]; then
        create_backup $SOURCE_FOLDER "${DESTINATION_FOLDER}/dailyBackups/daily_backup"
        daily_task_ran=true

        # Delete old backups once a day
        delete_old_backups $regular_backup_path
    fi

    # Create regular backup
    create_backup $SOURCE_FOLDER $regular_backup_path

    # Sleep for configured minutes
    sleep $((BACKUP_INTERVAL_MINUTES * 60))
done
