#!/bin/bash
# converts the date of emails to the system's local time
# Requires procmail
#
# On MacOS using homebrew:
# $ brew install coreutils procmail
# 
# Q:
# When I view a message in the pager mutt displays the time in the Date
# header in UTC rather than my local time zone. The index view displays
# the local time correctly. I found this old mailing list post that
# describes how to get the local time to display in the status bar at the
# bottom of the screen, but this still doesn't "fix" the time in the Date
# header at the top of the screen. Is there any way to get the pager to
# convert the Date header time to local time?
#
# A:
# The formatting in the index is controlled by the index_format setting --
# it's generated by mutt. The Date header isn't controlled by mutt, it's
# a header included with the message that just gets displayed. If it shows
# UTC time it's because the sending server decided to use UTC when generating
# the header. The only way to change it is to actually change the message
# itself, either when you receive it or when you view it.
# 
# Changing it as it comes in means adding a filter to your mail delivery
# agent, but it needs to be sophisticated enough to parse the existing Date
# header and rewrite it. It's almost certainly better to just have mutt
# reformat the message when you look at it. You can set the display_filter
# property to an executable file, and it will pipe any message you open
# through the executable before displaying it.
# 
# You'll need to write a program or shell script that reads each line of the
# message and replaces the one with the Date header, or find an existing
# script (there's one here that might work, although it doesn't seem like it
# should really be necessary to involve a temporary file)

TMPFILE=$(mktemp)

# save the message to a file
cat - >"$TMPFILE"
# extract the date header
DATE=$( formail -xDate: < "$TMPFILE" )

# convert to the current timezone (defined by TZ)
if [[ "$OSTYPE" == "darwin"* ]]; then
	DATE=$( gdate -R -d "$DATE" )
else
	DATE=$( date -R -d "$DATE" )
fi

# output the modified message
echo "Date: $DATE"
formail -fI Date < "$TMPFILE"
# clean up
rm -f "$TMPFILE"

