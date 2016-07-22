#!/bin/bash

# Get the folder of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGFILE="$DIR/mox.conf"
INCLUDEBEGINMARKER="### MOX INCLUDE BEGIN ###"
INCLUDEENDMARKER="### MOX INCLUDE END ###"


ADD_FILES=""
REMOVE_FILES=""
QUIET=0
while getopts "a:r:q" OPT; do
  case $OPT in
	a)
		ADD_FILES="$ADD_FILES $OPTARG"
		;;
	r)
		REMOVE_FILES="$REMOVE_FILES $OPTARG"
		;;
	q)
		QUIET=1
		;;
	*)
		echo "Usage: $0 [-a file] [-r file]"
		echo "	-a: Add file to include list"
		echo "	-r: Remove file from include list"
		exit 1;
		;;
	esac
done

if ! grep --fixed-strings --quiet "$INCLUDEBEGINMARKER" "$CONFIGFILE"; then
	if [ ! $QUIET ]; then
		echo "Begin marker not found"
	fi
	exit 1
fi

if ! grep --fixed-strings --quiet "$INCLUDEENDMARKER" "$CONFIGFILE"; then
	if [ ! $QUIET ]; then
		echo "End marker not found"
	fi
	exit 1
fi

for INCLUDEFILE in $ADD_FILES; do
	INCLUDELINE="Include $INCLUDEFILE"

	if [ ! -f $INCLUDEFILE ]; then
		if [ ! $QUIET ]; then
			echo "'$INCLUDEFILE' is not a file"
		fi
		exit 1
	fi

	if grep --fixed-strings --quiet "$INCLUDELINE" "$CONFIGFILE"; then
		if [ ! $QUIET ]; then
			echo "File $INCLUDEFILE is already included"
		fi
		exit 0
	fi

	REPLACELINE="$INCLUDELINE\n$INCLUDEENDMARKER"
	sed --in-place --expression="s/${INCLUDEENDMARKER}/${REPLACELINE//\//\\/}/" "$CONFIGFILE"
done


for INCLUDEFILE in $REMOVE_FILES; do
	INCLUDELINE="Include $INCLUDEFILE"

	if ! grep --fixed-strings --quiet "$INCLUDELINE" "$CONFIGFILE"; then
		if [ ! $QUIET ]; then
			echo "File $INCLUDEFILE is not included"
		fi
		exit 0
	fi

	SEARCHLINE="$INCLUDELINE"
	sed --in-place --expression="/${SEARCHLINE//\//\\/}/d" "$CONFIGFILE"
done
