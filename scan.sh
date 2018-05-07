#!/bin/bash
# usage: scan.sh [-d|--duplex] [-a|--append] [-c|--crop] [-z|--fuzz <0-100>] [-o|--output <filename>]
# Scans a set of pages and saves to pdf
# Features:
# - Autocrop
# - Duplex or simplex mode
# - Merging to existing pdf
# Tested with Canon imageFORMULA P-150 and Brother DSMobile 720D
# Requires SANE, imagemagick, pdftk

set -e

function view_result {
    if [ -f $HOME/.mailcap ]; then
        MAILCAP=$HOME/.mailcap
    else
        if [ -f /etc/mailcap ]; then
            MAILCAP=/etc/mailcap
        else
            return
        fi
    fi
    VIEWAPP=`grep 'application/pdf' $MAILCAP | awk -F\;  '{ print $2 }' | awk -F\  '{ print $1 }' | head -1`
    $VIEWAPP "$FILENAME"
}

# Set FEEDER=1 if scanner has a document feeder (e.g. Canon P-150)
# - Canon P-150 has a document feeder and scans both sides only if
#   ScanMode=Duplex is set
# - Brother 720D scans each side to separate pages
FEEDER=0

# Set device name
DEVICE_NAME="-d dsseries:usb:0x04F9:0x60E0"

# Autocrop fuzz in percent
FUZZ=15

AUTOCROP=0
PAPER_SIZE="-l 0 -t 0 -x 215 -y 297"
RESOLUTION="--resolution 300"
MODE="--mode Color"
DATE="`date +'%F_%T'`"
FILENAME="$DATE.pdf"
USAGE="usage: `basename $0` [-d|--duplex] [-a|--append] [-c|--crop] [-z|--fuzz <0-100>] [-o|--output <filename>]"

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o o:dacz: --long output:,duplex,append,crop,fuzz -n 'scan.sh' -- "$@"`
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
            DUPLEX=1
            # Only use ScanMode Duplex if scanner supports it
            if [ $FEEDER -eq 1 ] ; then
                OPTIONS=$OPTIONS" --ScanMode Duplex "
            fi
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
	-z|--fuzz)
            case "$2" in
                "")
                    shift 2
	            ;;
                *)
	            FUZZ="$2"
                    shift 2
                    ;;
            esac
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
scanimage $DEVICE_NAME $PAPER_SIZE $OPTIONS $RESOLUTION $MODE --format=tiff --batch="out%04d.tiff" || echo "Scan complete"

# Quit if no pages has been made scanned
if [ ! -e out0001.tiff ]; then
    exit
fi

# Autocrop
if [ $AUTOCROP -eq 1 ]; then
    for fil in out*.tiff
    do
        /usr/bin/convert $fil -crop `convert $fil -virtual-pixel edge -fuzz $FUZZ% -trim -format '%wx%h%O' info:` +repage c$fil
        mv c$fil $fil
    done
fi

# Only save first page
if [ $FEEDER -eq 0 ] && [ -z $DUPLEX ] ; then
    mv out0001.tiff temp.tiff
    rm out*.tiff
    mv temp.tiff out0001.tiff
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
if [ -e "$FILENAME" ]; then
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
view_result
