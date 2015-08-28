#!/bin/bash
# Scans a set of pages and saves to pdf
# Features:
# - Autocrop
# - Duplex or simplex mode
# - Merging to existing pdf
# Tested with Canon imageFORMULA P-150
# Requires SANE, imagemagick, pdftk
# usage: scan.sh [--duplex] [--autocrop] [--output <filename>] [--help]
# TODO: Exit if using unknown options

set -e
AUTOCROP=0
PAPER_SIZE="-l 0 -t 0 -x 215 -y 297"
RESOLUTION="--resolution 300"
MODE="--mode Color"
DATE="`date +'%F_%T'`"
FILENAME="$DATE.pdf"
VIEWAPP=`grep 'application/pdf' /etc/mailcap | awk -F\;  '{ print $2 }' | awk -F\  '{ print $1 }' | head -1`

for word in "$@"; do
  case "$word" in
    --output)
      shift
      FILENAME="${1}"
      ;;
    --duplex)
      shift
      DUPLEX="--ScanMode Duplex"
      ;;
    --autocrop)
      shift
      AUTOCROP=1
      ;;
    --help|-h)
      echo "Unknown option: $1"
      echo "usage: `basename $0` [--duplex] [--autocrop] [--output <filename>]"
      exit 1
      ;;
  esac
done

# Scan
scanimage $PAPER_SIZE $DUPLEX $RESOLUTION $MODE --format=tiff --batch="out%d.tiff" || echo "Scan complete"

# Autocrop
if [ $AUTOCROP -eq 1 ]; then
    for fil in out*.tiff
    do
        /usr/bin/convert $fil -crop `convert $fil -virtual-pixel edge -fuzz 15% -trim -format '%wx%h%O' info:` +repage c$fil
        mv c$fil $fil
    done
fi

# Convert
for fil in out*.tiff
do
    # Compress first to jpg 
    jfil=`basename $fil .tiff`.jpg
    /usr/bin/convert $fil -define jpg $jfil
    # Convert to pdf
    pfil=`basename $jfil .jpg`.pdf
    /usr/bin/convert $jfil -define pdf $pfil
    rm $fil
done

# Merge if output file already exists
if [ -d "$FILENAME" ]
    pdftk out*.pdf "$FILENAME" cat output "$FILENAME"-1
    mv "$FILENAME"-1 "$FILENAME"
    echo "Scan merged with $FILENAME"
else
    pdftk out*.pdf cat output "$FILENAME"
    echo "Scan saved to $FILENAME"
fi

# Remove temporary files
rm out*.pdf
rm out*.jpg

# View result
$VIEWAPP "$FILENAME"
