#!/bin/bash

#
# This script is licensed under NOLICENSE please don't take the piss
#
# project github is at https://github.com/d834256/ZIGGAZIGAH
# 

# if you set this you'll have subtitles on your final video
SUBTITLES="1"

# tolerance, ok, this is going to take some explaining.
#
# by default you end up with a clip that is exactly the length of one
# subtitle entry. The thing is these clips ary in length depending on
# the pace of the video content. Dramas may be drawn out with slow
# dialogue, action based stuff will be quicker. So if you're not careful
# you're going to have a collection of quickly flashing videos and you'll
# be on the floor having some kind of seizure. So to make this a bit easier
# on the eyes you can add a tolerance which basically adds as many extra
# subtitle entries as you like to make the clips longer.
#
TOLERANCE="0"

#
# change this if you want your db to live somewhere else
#
database="./worddb.sqlite"

# we increment this in a pattern
counter="0"

# pull in our shared functions
. $(dirname "$0")/functions.sh

filename_prefix=$(date +%Y%m%d%H%M%S)

if [ ! "${1}" ]; then
    usage_warning="1"
fi

if [ "${1}" != "random" ] && [ "${1}" != "keywords" ]; then
    usage_warning="1"
fi

if ([ "${1}" == "random" ] || [ "${1}" == "keywords" ]) && [ ! "${2}" ]; then
    usage_warning="1"
fi

if [ "${1}" == "random" ]; then
    mode="random"
    sublines="${2}"
fi

if [ "${1}" == "keywords" ]; then
    mode="keywords"
    words="${2}"
fi

if [ "${usage_warning}" == "1" ]; then 
    scriptname=$(basename -- "${0}")
    echo ""
    echo "Usage : ${scriptname} keywords [comma separated keywords]"
    echo ""
    echo "Usage : ${scriptname} random [number of subtitle lines]"
    echo ""
    exit 1
fi

if [ ! -d "./tmp" ]; then
    echo "Creating ./tmp"
    mkdir tmp
fi

echo "Mode: ${mode}"

if [ "${mode}" == "random" ]; then
    echo "${sublines} lines of random subtitles."

    sql="SELECT id from words order by RANDOM() LIMIT ${sublines};"
    results=$(sqlite3 ${database} "${sql}")

    echo ${result}

    for result in ${results}; do
        id="${result}"
        padded=$(printf "%05d\n" ${counter})
        extract_clip "${filename_prefix}_${padded}" "${id}" "${SUBTITLES}" "${TOLERANCE}"

        echo "file '${filename_prefix}_${padded}.mp4'" >> ./tmp/${filename_prefix}.txt

        counter=$((counter+1))
    done

    echo "Combining all the clips to ./tmp/${filename_prefix}_final.mp4"
    ffmpeg -loglevel 0 -f concat -safe 0 -i ./tmp/${filename_prefix}.txt -codec copy ./tmp/${filename_prefix}_final.mp4

fi

if [ "${mode}" == "keywords" ]; then
    echo "Using keywords: ${words}"

    for word in ${words}; do
        result=$(search_for_word "${word}")

        if [[ "${result}" = *[[:space:]]* ]]; then

            resultarr=( $result )
            resultcount=${#resultarr[@]}

            random=$(( ( RANDOM % ${resultcount} ) ))

            id=${resultarr[${random}]}
            padded=$(printf "%05d\n" ${counter})
            extract_clip "${filename_prefix}_${padded}" "${id}" "${SUBTITLES}" "${TOLERANCE}"

            echo "file '${filename_prefix}_${padded}.mp4'" >> ./tmp/${filename_prefix}.txt

            counter=$((counter+1))
        elif [ "${result}" != "0" ] || [ "${result}" != "" ]; then
            id=${result}
            padded=$(printf "%05d\n" ${counter})
            extract_clip "${filename_prefix}_${padded}" "${id}" "${SUBTITLES}" "${TOLERANCE}"
            echo "file '${filename_prefix}_${padded}.mp4'" >> ./tmp/${filename_prefix}.txt
            counter=$((counter+1))
        else
            echo "WARNING: word ${word} wasn't found in the database."
        fi 
    done

    echo "Combining all the clips to ./tmp/${filename_prefix}_final.mp4"
    ffmpeg -loglevel 0 -f concat -safe 0 -i ./tmp/${filename_prefix}.txt -codec copy ./tmp/${filename_prefix}_final.mp4
    errorcode="${?}"
    if [ "${errorcode}" == "1" ]; then
        echo ""
        echo "ERROR: ffmpeg combined failed."
        echo ""
        echo "ffmpeg command line was :"
        echo ""
        echo "ffmpeg -loglevel 0 -f concat -safe 0 -i ./tmp/${filename_prefix}.txt -codec copy ./tmp/${filename_prefix}_final.mp4"
        echo ""
        exit 1
    fi 
fi

#
# TODO -
#
# something to prevent duplicate clips
