#!/bin/sh -
#
# Script to extract data from an Apple WikiServer's data store by querying the
# filesystem itself. Creates a 'wikipages.csv' file that's readable by any
# spreadsheeting application, such as Numbers.app or Microsoft Excel.app.
#
# USAGE:   To use this script, change to the WikiServer's pages directory, then
#          just run this script. A file named wikipages.csv will be created in
#          your current directory. For instance:
#
#              cd /Library/Collaboration/Groups/mygroup/wiki  # dir to work in
#              wikipages2csv.sh                               # run the script
#              cp wikipages.csv ~/Desktop                     # save output
#
# WARNING: Since the WikiServer's files are only accessible as root, this script
#          must be run as root to function. Additionally, this is not extremely
#          well tested, so use at your own risk.
#
# Author:  Meitar Moscovitz
# Date:    Mon Sep 22 15:03:54 EST 2008

##### CONFIGURE HERE ########

# The prefix to append to generated links. NO SPACES!
WS_URI_PREFIX=http://my-server.example.com/groups/wiki/

##### END CONFIGURATION #####
# DO NOT EDIT PAST THIS LINE
#############################

WS_CSV_OUTFILE=wikipages.csv
WS_PAGE_IDS_FILE=`mktemp ws-ids.tmp.XXXXXX`

function extractPlistValueByKey () {
    head -n \
      $(expr 1 + `grep -n "<key>$1</key>" page.plist | cut -d ':' -f 1`) page.plist | \
        tail -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
}

function linkifyWikiServerTitle () {
    echo $1 | sed -e 's/ /_/g' -e 's/&amp;/_/g' -e 's/&gt;/_/g' -e 's/&lt;/_/g' -e 's/\?//g'
}

function formatISO8601date () {
    echo $1 | sed -e 's/T/ /' -e 's/Z$//'
}

function csvQuote () {
    echo $1 | grep -q ',' >/dev/null
    if [ $? -eq 0 ]; then # if there are commas in the string
        echo '"'"$1"'"'   # quote the value
    else
        echo "$1"         # just output the as it was received
    fi
}

ls -d [^w]*.page | \
  sed -e 's/^\([a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]\)\.page$/\1/' > $WS_PAGE_IDS_FILE

echo "Title,ID,Date Created,Last Modified,URI" > $WS_CSV_OUTFILE
while read id; do
    cd $id.page
    title="$(extractPlistValueByKey title)"
    created_date="$(formatISO8601date $(extractPlistValueByKey createdDate))"
    modified_date="$(formatISO8601date $(extractPlistValueByKey modifiedDate))"
    link=$WS_URI_PREFIX"$id"/`linkifyWikiServerTitle "$title"`.html
    cd ..
    echo `csvQuote "$title"`,$id,$created_date,$modified_date,`csvQuote "$link"` >> $WS_CSV_OUTFILE
done < $WS_PAGE_IDS_FILE
rm $WS_PAGE_IDS_FILE
