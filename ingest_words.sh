#!/bin/bash

#
# This script is licensed under NOLICENSE please don't take the piss
#
# project github is at https://github.com/d834256/ZIGGAZIGAH
# 

# enable this for debug output
DEBUG="0"

#
# change this if you want to limit the type of your input files
#
# media_file_types="avi mkv mp4"

#
# this is the path to your database file, default assumes current working directory
#
database="./worddb.sqlite"

#
# source our shared functions
#
. $(dirname "$0")/functions.sh

# we need sqlite3 or we can't run
check_is_in_path "sqlite3"

#
# if our db does not exist then we initialise it
#
if [ ! -f "${database}" ]; then
	echo "No database found, initialising a new one."
	initialise_db "${database}"
fi

#
# we check firstly that the first argument was passed and then 
# if the file exists
#
if [ ! "${1}" ] && [ ! -f "${1}" ] ; then
    echo ""
    echo "ARGS: ${0} <input file>"
    echo ""
    echo "You need to provide a input file to make this"
    echo "script work, one directory or filename PER LINE"
    echo ""
fi

#
# iterate over our input file, at this point we want to check the
# file line by line, verify that our input is good and that we can
# find subtitle files for either the contents of the directory or
# for the movie file we have been passed
#

# make a note of our start time
startdate=$(date +%s)
#echo "Run started at ${startdate}"

IFS=''
cat ${1} | while read LINE; do
    
    if [ -f "${LINE}" ]; then
    	line_type="file"
    	line_dir=$(dirname ${LINE})

        dirname=$(dirname ${LINE})
        filename=$(basename -- "${LINE}")
        extension="${filename##*.}"
        filename_base="${filename%.*}"
 
        check_subtitles_exist "${dirname}/${filename_base}"

        is_file_new=$(check_db_for_filename "${LINE}")

        if [ "${is_file_new}" == "NOTFOUND" ]; then
            echo "${LINE} is new, trying to add to db"
            add_new_subs "${dirname}/${filename_base}" "${extension}"
        fi

    elif [ -d "${LINE}" ]; then

        find "${LINE}" -type f -regextype posix-extended -iregex \
            ".*\.(avi|mp4|mkv)" -print0 |
            while IFS= read -r -d '' file; do
        	    debug ${file}
        	    dirname=$(dirname ${file})
                filename=$(basename -- "${file}")
                extension="${filename##*.}"
                filename_base="${filename%.*}"

                check_subtitles_exist "${dirname}/${filename_base}"

                is_file_new=$(check_db_for_filename "${file}")
                
                if [ "${is_file_new}" == "NOTFOUND" ]; then
                    echo "${file} is new, trying to add to db"
                    add_new_subs "${dirname}/${filename_base}" "${extension}"

                fi
            done

     	line_type="directory"
    	line_dir="${LINE}"
    else
    	#
    	# If you reach this part, this means you had a error in your
    	# input file. Maybe a typo in the path or filename.
    	#
        echo ""
        echo "There is a problem with this line: ${LINE}"
        echo ""
        exit 1
    fi

done

# make a note of our end time
enddate=$(date +%s)

#
# https://stackoverflow.com/questions/42149301/how-to-translate-seconds-to-minutes-seconds-in-bash
# 
total_time=$((enddate-startdate))
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script took $minutes minutes and $seconds seconds to complete."
