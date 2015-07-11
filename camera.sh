#!/bin/bash
# camera.sh
# Move all photos from memory card to a given folder
# Sort photos into sub folders based on date in EXIF data
# Requires ImageMagick
set -e

ORIGIN=`mount | grep mmcblk0p1 | awk '{print $3}'`
DEST=~/Bilder


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

# Moves file names ending with MP4
find $ORIGIN -iregex ".*MP4" -prune -print0 | while read -d $'\0' file
do
    echo "Moving $file..."
    if [ ! -d "$DEST" ]; then
        mkdir -p "$DEST"
    fi
    mv -i "$file" "$DEST"
done
