#!/bin/bash
# camera.sh
# Move all photos from memory card to a given folder
# Sort photos into sub folders based on date in EXIF data
# Requires ImageMagick and gphoto2
set -e

DEST=~/photos
USAGE="usage: `basename $0` [-m|--memory-card] [-g|--gphoto2]"
GPHOTO2=1

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi


TEMP=`getopt -o mg --long memory-card,gphoto2 -n 'camera.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
	case "$1" in
		-m|--memory-card)
			GPHOTO2=0
			;;
		-g|--gphoto2)
			GPHOTO2=1
			;;
		--) shift ; break ;;
	esac
done

# Gphoto2
if [ $GPHOTO2 -eq 1 ]; then
	ORIGIN=`mktemp -d`
	cd $ORIGIN
	gphoto2 --get-all-files
	cd ..
else
	ORIGIN=`mount | grep camera | awk '{print $3}'`
fi

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

if [ $GPHOTO2 -eq 1 ]; then
	rm -rf $ORIGIN
fi
