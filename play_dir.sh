#!/bin/bash

# 0 = true

# One-liner for playing current dir
# IFS=$'\n'; for f in $(ls -rt .); do echo "Playing $f..." ; mplayer --msglevel=all=-1 "./$f"; done; IFS=' '

# One-liner unrolled
# IFS=$'\n'
# for f in $(ls -rt "$1"); do
# 	echo "Playing $f..."
# 	mplayer --msglevel=all=-1 "./$f"
# done
# IFS=' '

REPORT_ERRORS=0
RNDM=1
CURRENT_DIR=`pwd`
#SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

error()
{
	if [ $REPORT_ERRORS -eq 0 ]; then
		echo -n "Error    : "
		if [ -z "$1" ]; then
			return 1
		fi
		until [ -z "$1" ]; do
			echo -ne "$1"
			echo -n " "
			shift
		done
		echo
	fi
	return 0
}

usage()
{
	echo -e "Usage:\n\t#bash `basename $0` [options]... <directory>\n"
	echo "Options:"

	echo -e "\t-r"
	echo -e "\t\tRandom"
	echo -e "\t\tPlay files in directory in random order"
	echo -e "\r"

# 	echo
# 	echo "Example usage:"
# 	echo -e "\tCrop images in dir"
# 	echo -e "\t\t#bash `basename $0` -c"
# 	echo -e "\tCrop for animation use (Equally sized frames)"
# 	echo -e "\t\t#bash `basename $0` -a"
}

die()
{
	usage
	echo -e "\nThe script didn't finish execution due to following errors:"
	error $1
	 #echo >&2 "$@"
	cd $CURRENT_DIR
    exit 1
}

check_exes()
{
	command -v mplayer >/dev/null 2>&1 || { echo >&2 "This script requires the command line tool \"mplayer\" to run"; exit 1; }
	command -v md5sum >/dev/null 2>&1 || { echo >&2 "This script requires the command line tool \"md5sum\" to run"; exit 1; }
}


#----------------- Main ------------------------
#---- User option handling ----
[ "$#" -gt 0 ] || die "Arguments required, $# provided"
check_exes

while getopts "r" OPTION
do
	case $OPTION in
		r ) RNDM=0;;
		* ) die "One or more options not recognized...";; # DEFAULT
	esac
done
shift $(($OPTIND - 1)) # Move argument pointer to next argument.


FROM_INDEX=1
if [ ! -z "$2" ]; then
	FROM_INDEX=$2
fi

CIFS=$IFS
IFS=$'\n'
INDEX=1


sort_cmd="sort -zk 1n"
if [ $RNDM -eq 0 ]; then
	sort_cmd="sort -Rz"
fi
TOTAL=$((($(ls -l $1 | grep -v ".directory" | wc -l)-1)))

for FILE in $(find $1 -type f -printf '%T@ %p\0' | eval $sort_cmd | sed -z 's/^[^ ]* //' |xargs -0n1 | grep -v ".directory"); do
#for FILE in $(find $1 -type f -printf '%T@ %p\0' | sort -Rz | sed -z 's/^[^ ]* //' |xargs -0n1 | grep -v ".directory"); do
#for FILE in $(find $1 -type f -printf '%T@ %p\0' | sort -zk 1n | sed -z 's/^[^ ]* //' |xargs -0n1 | grep -v ".directory"); do
	if (( $INDEX >= $FROM_INDEX )); then
		INFO=$(mplayer -vo null -ao null -frames 0 -identify "$FILE" 2>/dev/null | sed -ne '/^ID_/ { s/[]()|&;<>`'"'"'\\!$" []/\\&/g;p }')
		LENGTH=$(echo "$INFO" | grep "ID_LENGTH" | sed 's/ID_LENGTH\=//')
		MD5=`md5sum ${FILE} | awk '{ print $1 }'`
		
		FILENAME=$(basename "$FILE")
		
		TXT="Playing $INDEX/$TOTAL $MD5 ($LENGTH) $FILE...\n"
		printf "$TXT"
		
		if hash kdialog 2>/dev/null; then
			kdialog --title "Now playing $FILENAME" --passivepopup "$TXT" 20
		fi
		
		mplayer -vo null --msglevel=all=-1 "$FILE"
	fi
	INDEX=$(($INDEX+1))
done
IFS=$CIFS