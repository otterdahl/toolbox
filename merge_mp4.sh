#!/bin/bash
# Merge mp4 files using ffmpeg
# See also https://trac.ffmpeg.org/wiki/Concatenate
set -e

USAGE="usage: `basename $0` [-o|--output <filename>] <input file(s)>"
INPUT=()

# Default output name
OUTPUT="output.mp4"

# Exit if no input files
if [ -z "$1" ]; then
    echo $USAGE
    exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o o: --long output: -n 'merge_mp4.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
    case "$1" in
        -o|--output)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    OUTPUT="$2"
                    shift 2
                    ;;
            esac
            ;;
	--) shift; break ;;
    esac
done

# Deal with spaces in filenames
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Add input files
while [ -n "$1" ]; do
        INPUT+=($1)
        shift;
done

PARTS=$(mktemp merge_mp4.XXXXXXXXXX)
for ITEM in ${INPUT[*]}
do
	echo "file '$ITEM'" >> $PARTS
done

ffmpeg -f concat -safe 0 -i "$PARTS" -c copy $OUTPUT
rm -f "$PARTS"

# Restore IFS
IFS=$SAVEIFS

