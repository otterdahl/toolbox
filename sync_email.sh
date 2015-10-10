#!/bin/bash
# Sync offlineimap
# 1, Only run one instance at a time
# 2, Disable sync if incorrect password
F=~/config/email_sync_enabled
if [ `cat $F` -ne "1" ]; then
    exit 1;
fi
echo 0 > $F

offlineimap $@ 2>&1 | grep -q 'LOGIN authentication failed'
S=$?
if [ $S -ne 0 ]; then
    # Login successful
    echo 1 > $F
fi 
