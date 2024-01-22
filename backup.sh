#!/bin/bash

# Set variables for intervals
BACKUP_INTERVAL_MINUTES=30 #how many minutes to wait between backups
DAILY_BACKUP_HOUR=24 #hour in which the daily backup will be created
DAILY_RESET_HOUR=23 #Needs to be different than DAILY_BACKUP_HOUR. TODO: refactor to remove this. Can't just add or sub 1 because I could end up with -1 or 25

# Set variables for folders
PARENT_FOLDER="path/to/folder"
SOURCE_FOLDER="${PARENT_FOLDER}/folderNameHere"
DESTINATION_FOLDER="${PARENT_FOLDER}/backups"

# Variable to track daily backup status
daily_backup_created=false

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
    find "$backup_folder" -type d -mtime +30 -exec rm -r {} \;
    echo "Old backups deleted."
}

#make dirs if needed
mkdir -p $DESTINATION_FOLDER
mkdir -p "${DESTINATION_FOLDER}/regularBackups"
mkdir -p "${DESTINATION_FOLDER}/dailyBackups"

# Main loop
while true; do
    current_hour=$(date '+%H')
    regular_backup_path="${DESTINATION_FOLDER}/regularBackups/regular_backup"

    # Check if it's time for a daily backup
    if [ "$current_hour" -eq "$DAILY_BACKUP_HOUR" ] && [ "$daily_backup_created" = false ]; then
        create_backup $SOURCE_FOLDER "${DESTINATION_FOLDER}/dailyBackups/daily_backup"
        daily_backup_created=true
    fi

    # Once the daily backup hour has passed, reset the daily_backup flag
    if [ "$current_hour" -eq "$DAILY_RESET_HOUR" ]; then
        daily_backup_created=false
    fi

    # Create regular backup
    create_backup $SOURCE_FOLDER $regular_backup_path

    # Delete old backups once a day
    if [ "$current_hour" -eq "$DAILY_BACKUP_HOUR" ]; then
        delete_old_backups $regular_backup_path
    fi

    # Sleep for configured minutes
    sleep $((BACKUP_INTERVAL_MINUTES * 60))
done
