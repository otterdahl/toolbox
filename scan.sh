#!/bin/bash
# usage: scan.sh [-d|--duplex] [-a|--append] [-c|--crop] [-o|--output <filename>]
# Scans a set of pages and saves to pdf
# Features:
# - Autocrop
# - Duplex or simplex mode
# - Merging to existing pdf
# Tested with Canon imageFORMULA P-150
# Requires SANE, imagemagick, pdftk
# TODO: Sorts pages incorrectly when scanning more than 9 pages

set -e
AUTOCROP=0
PAPER_SIZE="-l 0 -t 0 -x 215 -y 297"
RESOLUTION="--resolution 300"
MODE="--mode Color"
DATE="`date +'%F_%T'`"
FILENAME="$DATE.pdf"
VIEWAPP=`grep 'application/pdf' /etc/mailcap | awk -F\;  '{ print $2 }' | awk -F\  '{ print $1 }' | head -1`
USAGE="usage: `basename $0` [-d|--duplex] [-a|--append] [-c|--crop] [-o|--output <filename>]"

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o o:dac --long output:,duplex,append,crop -n 'scan.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
    case "$1" in
        -o|--output)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    FILENAME="$2"
                    shift 2
                    ;;
            esac
            ;;
        -d|--duplex)
            DUPLEX="--ScanMode Duplex"
            shift
            ;;
        -a|--append)
            APPEND=1
            shift
            ;;
        -c|--crop)
            AUTOCROP=1
            shift
            ;;
        --) shift ; break ;;
    esac
done

# Check if output file exists
if [ -a "$FILENAME" ] && [ -z $APPEND ]; then
    echo File already exists
    exit 1
fi

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
if [ -a "$FILENAME" ]; then
    pdftk "$FILENAME" out*.pdf cat output "$FILENAME"-1
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
