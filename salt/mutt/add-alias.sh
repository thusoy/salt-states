#!/bin/sh

MESSAGE=$(cat)
ALIAS_FILE=~/.mutt/aliases

echo "${MESSAGE}"

NEWALIAS=$(echo "${MESSAGE}" | grep ^"From: " | sed s/[\,\"\']//g | awk '{$1=""; if (NF == 3) {print "alias" $0;} else if (NF == 2) {print "alias" $0 $0;} else if (NF > 3) {print "alias", tolower($2)"-"tolower($(NF-1)) $0;}}')

if grep -Fxq "$NEWALIAS" $ALIAS_FILE; then
    :
else
    echo "$NEWALIAS" >> $ALIAS_FILE
fi
