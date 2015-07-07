#!/bin/bash
# camera.sh
# Move all photos from memory card to a given folder
# Sort photos into sub folders based on date in EXIF data
set -e

ORIGIN=/mnt/mmcblk0p1
DEST=~/Bilder

mount | grep $ORIGIN || mount $ORIGIN

# Moves file names ending with JPG
find $ORIGIN -iregex ".*JPG" -prune -print0 | while read -d $'\0' file
do
    echo "Moving $file..."
    DATE=`identify -verbose "$file" | grep exif:DateTime: | awk -F\  '{print $2}' | sed s/:/-/g`
    if [ ! -d "$DEST/$DATE" ]; then
        mkdir -p "$DEST/$DATE"
    fi
    mv -i "$file" "$DEST/$DATE"
done

umount $ORIGIN
