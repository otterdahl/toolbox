#!/bin/bash
# usage: pdf_rotate.sh [-r|--range <range>] [-a|--angle <-90,0,90,180>] <filenames>
#        range: e.g. "2-3". Commas are not supported
#        angle, e.g. "-90", "90", "180"
# Basically a wrapper around pdftk for common rotate operations

set -e

USAGE="usage: `basename $0` [-r|--range <range, e.g. 1-3>] [-a|--angle [-90,0,90,180] [<filenames>]"
INPUT=()

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
    for ITEM in ${INPUT[*]}
    do
    	$VIEWAPP "$ITEM"
    done
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o r:a: --long range:,angle: -n 'pdf_rotate.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
    case "$1" in
        -r|--range)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    RANGE="$2"
                    shift 2
                    ;;
            esac
            ;;
        -a|--angle)
            case "$2" in
                "")
                    shift 2
                    ;;
                "-90")
                    ANGLE="left"
                    shift 2
                    ;;
                "90")
                    ANGLE="right"
                    shift 2
                    ;;
                "180")
                    ANGLE="down"
                    shift 2
                    ;;
            esac
            ;;
        --) shift ; break ;;
    esac
done

# Deal with spaces in filenames
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Exit if no input files
if [ -z "$1" ]; then
    echo $USAGE
    exit 1
fi

# Add input files
while [ -n "$1" ]; do
	INPUT+=($1)
	shift;
done

# if no range is defined, set RANGE=1
if [ -z $RANGE ]; then
    RANGE="1"
fi

NUMPAGES=`pdftk "$INPUT" dump_data | grep NumberOfPages | awk '{print $2}'`
START=`echo $RANGE | awk -F"-" '{print $1} '`
END=`echo $RANGE | awk -F"-" '{print $2} '`

# if only a single page is defined in the range, set end same as start
if [ -z $END ]; then
    END=$START
fi

# Define ranges for the other pages which are not rotated
if [ "$START" -gt 1 ]; then
    PRE=1-$(($START - 1))
fi

if [ "$NUMPAGES" -gt "$END" ]; then
    POST=$(($END + 1))-$NUMPAGES
fi

OUTPUT=temp.pdf
for ITEM in ${INPUT[*]}
do
    pdftk "$ITEM" cat $PRE $RANGE$ANGLE $POST output "$OUTPUT"
    mv -f "$OUTPUT" "$ITEM"
done

# View result
view_result

# Restore IFS
IFS=$SAVEIFS
