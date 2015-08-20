#!/bin/bash
# Usage: audiorecord [output directory]

# Record audio using default mic for 9 hours
MINUTES=540
FILENAME="`date +'%F_%H:%M'`.ogg"
timeout "$MINUTES"m arecord -f cd -q -t raw | oggenc - -r -Q -o $FILENAME

mv $FILENAME "$HOME/$1"
