#!/bin/bash

#
# This script is licensed under NOLICENSE please don't take the piss
#
# project github is at https://github.com/d834256/ZIGGAZIGAH
# 

# vanity, nothing else
VERSION="0.1"

function check_is_in_path () {
    if ! type "${1}" > /dev/null; then
        echo ""
        echo "${1} is not in your PATH"
        echo ""
        exit 1
    fi
}

function check_subtitles_exist () {
	if [ ! -f "${1}.srt" ]; then
        echo ""
        echo "Subtitle file not found: ${1}.srt"
        echo ""
        exit 1
    else
        debug "Subtitle file found: ${1}.srt"
    fi
}

function initialise_db () {
	sqlite3 ${1} "CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, \
	    filename varchar(4096), starttime varchar(16), endtime varchar(10), \
	    words varchar(4096), orig_words varchar(4096));"
}

function check_db_for_filename () {
    result=$(sqlite3 "${database}" "SELECT count() from words where \
        filename=\"${1}\";")
    if [ "${result}" == "0" ]; then
    	debug "${1} not found in db"
    	local db_result="NOTFOUND"
    	echo "${db_result}"
    fi
}

function add_new_subs () {
    outputline=""
    words=""
    starttime=""
    endtime=""
    orig_words=""

	while IFS= read -r line; do
		orig_line=${line}

		if [[ "${line}" == "" ]] || [[ "${line}" != *[![:space:]]* ]]; then
            
            #
            # yeah, I know
            #
            if [[ "${words}" =~ "www.OpenSubtitles.org" ]]; then
            	echo "advert in subs file, skipping db insert..."
            else
			    debug "Empty or non-blank line"
			    debug "${line}"

		        words=$(echo "${words}"|sed "s/'/\'/g")
		        words=$(echo "${words}"|sed "s/\"/\'/g")
		        orig_words=$(echo "${orig_words}"|sed "s/'/\'/g")
		        orig_words=$(echo "${orig_words}"|sed "s/\"/\'/g")

		        debug "WORDS ${words}"

                if [ "${starttime}" != "" ]; then
                    #
                    # sometimes a malformed line slips through, and our manipulation fails
                    # if this is the case we sacrifice the line rather than risk poluting the data
                    #
		            sql="INSERT INTO words  (filename, starttime, endtime, words, orig_words) VALUES (\"${1}.${2}\",\"${starttime}\", \"${endtime}\", \"${words}\", \"${orig_words}\");"

		            echo "${starttime} ${endtime} ${id} ${filename}"
		            sqlite3 "${database}" "${sql}"
                fi
            fi

		    debug "writing to db: ${starttime} ${endtime} ${words}" # ${outputline}"
		    outputline=""
            words=""
            starttime=""
            endtime=""
            orig_words=""
		else
            #
            # this is the ID line
            #
			if [[ "${words}" == "" ]]; then
				id="${line}"                
				id=$(echo ${id}|tr -d '\n')
                id=$(echo ${id}|sed $'s/\r//')
                line=""
			fi
            #
            # process the time code line
            #
            if [[ "${line}" =~ ' --> ' ]]; then
            	line=$(echo ${line}|sed -r 's/^\s+[0-9]+\s+//')
                line=$(echo ${line}|tr -d '\n')
                line=$(echo ${line}|sed $'s/\r//')
  
                starttime="${line:0:12}"
                starttime=$(echo ${starttime}|sed -r 's/,/./')
                endtime="${line:17:33}"
                endtime=$(echo ${endtime}|sed -r 's/,/./')
            else
                #
                # if the input line doesn't have --> then it's
                # dialogue lines and we process it accordingly
                #
                if [ "${words}" == " " ]; then
                    orig_words="${line}"
                else
                    orig_words="${orig_words} ${line}"
                    orig_words=$(echo ${orig_words}|sed -e 's/\^M/\n/g')
                fi

                #
                # this is a bit of a soupy mess, pretty sure some of
                # these lines do the same thing...
                #
                line="${line//[^[:ascii:]]/}"
                line=$(echo ${line}|tr -d '\n')
                line=$(echo ${line}|sed -e 's/\r//g')
                line=$(echo ${line}|sed -e 's/\r//g')
                line=$(echo ${line}|sed -e 's/\^M/\n/g')
                line=$(echo ${line}|sed -e 's/[0-9]+ //')
                line=$(echo ${line}|sed -E 's/\x1b\[[0-9]*;?[0-9]+m//g')

                if [ "${words}" == " " ]; then
                    words="${line}"
                else
                    words="${words} ${line}"
                fi
		    fi
	    fi
        
    done < "${1}.srt"
}

function debug () {
	if [ "${DEBUG}" == "1" ]; then
		echo "DEBUG: ${1}"
	fi
}

function search_for_word () {
	sql="SELECT id from words where words like \"%${1}%\";"
	#echo ${sql}
	result=$(sqlite3 ${database} "${sql}")
	echo "${result}"
}

# these three functions care of stack exchange
#
# https://unix.stackexchange.com/questions/426724/subtract-two-time-codes
#
# converts HH:MM:SS.sss to fractional seconds
function codes2seconds() (
    local hh=${1%%:*}
    local rest=${1#*:}
    local mm=${rest%%:*}
    local ss=${rest#*:}
    printf "%s" $(bc <<< "$hh * 60 * 60 + $mm * 60 + $ss")
)

# converts fractional seconds to HH:MM:SS.sss
function seconds2codes() (
    local seconds=$1
    local hh=$(bc <<< "scale=0; $seconds / 3600")
    local remainder=$(bc <<< "$seconds % 3600")
    local mm=$(bc <<< "scale=0; $remainder / 60")
    local ss=$(bc <<< "$remainder % 60")
    printf "%02d:%02d:%06.3f" "$hh" "$mm" "$ss"
)

function subtracttimes() (
    local t1sec=$(codes2seconds "$1")
    local t2sec=$(codes2seconds "$2")
    printf "%s" $(bc <<< "$t2sec - $t1sec")
)

function extract_clip () {

    # first up see what tolerance we're working at because
    # this is going to involve MATH and we just love the mess
    # that makes all over our functions

    tolerance=${4}
    id=${2}

    timecounter="0"

    max_id=${2}
    ((max_id+=${tolerance}))

    if [[ "${tolerance}" -gt "${id}" ]]; then
        #echo "${tolerance} is greater than ${id}"
        min_id="1"
    else
        min_id=$((${id} - ${tolerance}))
    fi

    total_seconds="0"
    min_timecode=""
    max_timecode=""
    offset="0"

    for ((i=${min_id};i<=${max_id};i++)); do
        sql="SELECT filename from words where id=\"${i}\";"
        filename=$(sqlite3 ${database} "${sql}")
        sql="SELECT starttime from words where id = \"${i}\";"
        starttime=$(sqlite3 ${database} "${sql}")
        sql="SELECT endtime from words where id = \"${i}\";"
        endtime=$(sqlite3 ${database} "${sql}")
        sql="SELECT words from words where id = \"${i}\";"
        words=$(sqlite3 ${database} "${sql}")

        if [ "${i}" == "${min_id}" ]; then
            min_timecode="${starttime}"
        fi
        if [ "${i}" == "${max_id}" ]; then
            max_timecode="${endtime}"
        fi
    
        if [ "${i}" == "${min_id}" ]; then
            offset="${starttime}"
        fi

        # if subtitles are turned on we need to create the .srt files as well
        if [ "${3}" == "1" ]; then
            length="0"

            sql="SELECT orig_words from words where id = \"${i}\";"
            orig_words=$(sqlite3 ${database} "${sql}")
            orig_words=$(echo "${orig_words}"|sed "s/''/'/g")

            start_timecode=$(subtracttimes "${offset}" "${starttime}")
            start_timecode=$(seconds2codes "${start_timecode}")

            end_timecode=$(subtracttimes "${offset}" "${endtime}")
            end_timecode=$(seconds2codes "${end_timecode}")

            echo "${timecounter}" >> ./tmp/${1}.srt
            echo "${start_timecode} --> ${end_timecode}" >> ./tmp/${1}.srt
            echo "${orig_words}" >> ./tmp/${1}.srt
            echo "" >> ./tmp/${1}.srt

            ((timecounter+=1))
        fi
        echo "${starttime} ${words}"
    done
    
    # sometimes if there time window is too low the extract files, so lets add 
    # some debugging to see if we find this is the case
    # super hokey as this is testing a bug right now
    test=$(subtracttimes "${min_timecode}" "${max_timecode}")
    testdur=$(ffprobe -v error -show_format -show_streams -i "${filename}"|grep duration=|grep -v "N/A"|uniq|awk -F= '{print $2}')
    testdur=$(echo ${testdur}|awk -F. '{print $1}')

    testmaxtimecode=$(codes2seconds "${max_timecode}")
    testmaxtimecode=$(echo ${testmaxtimecode}|awk -F. '{print $1}')

    if [ "${testmaxtimecode}" -gt "${testdur}" ]; then
        echo "*** WARNING: timecode exceeds length of video source       ***"
        echo "*** this usually means your subtitles file isn't correct   ***"
        echo "*** working around by randomly picking a time window       ***"
        echo "*** within the real duration and then reuse the bogus subs ***"
        echo "*** to get past this error, sorry!                         ***"

        min_timecode=$(codes2seconds "${min_timecode}")
        max_timecode=$(codes2seconds "${max_timecode}")
        min_timecode=$(echo ${min_timecode}|awk -F. '{print $1}')
        max_timecode=$(echo ${max_timecode}|awk -F. '{print $1}')

        min_milli=$((1 + $RANDOM % 100))
        min_milli=$(printf "%03d\n" ${min_milli})
        max_milli=$((1 + $RANDOM % 100))
        max_milli=$(printf "%03d\n" ${max_milli})

        min_timecode=$((30 + $RANDOM % ${testdur}))
        max_timecode=$((${min_timecode} + 2))

        max_timecode="${max_timecode}.${max_milli}"
        min_timecode="${min_timecode}.${min_milli}"

        max_timecode=$(seconds2codes "${max_timecode}")
        min_timecode=$(seconds2codes "${min_timecode}")
    fi

    ffmpeg -loglevel 0 -ss "${min_timecode}" -to "${max_timecode}" -i "${filename}" -c:v libx264 -crf 30 ./tmp/${1}.mp4
    errorcode="${?}"
    if [ "${errorcode}" == "1" ]; then
        echo "*** WARNING: bframes detected, applying fix to ./tmp/bframes.avi ***"
        ffmpeg -i "${filename}" -codec copy -bsf:v mpeg4_unpack_bframes ./tmp/bframes.avi
        ffmpeg -loglevel 0 -ss "${min_timecode}" -to "${max_timecode}" -i "./tmp/bframes.avi" -c:v libx264 -crf 30 ./tmp/${1}.mp4
        rm ./tmp/bframes.avi
    fi

    if [ "${3}" == "1" ]; then
        ffmpeg -loglevel 0 -i "./tmp/${1}.mp4" -vf subtitles="./tmp/${1}.srt" ./tmp/out.mp4
        errorcode="${?}"
        if [ "${errorcode}" == "1" ]; then
            echo ""
            echo "ERROR: ffmpeg subtitle burn failed."
            echo ""
            echo "ffmpeg command line was : "
            echo ""
            echo "ffmpeg -loglevel 0 -i \"./tmp/${1}.mp4\" -vf subtitles=\"./tmp/${1}.srt\" ./tmp/out.mp4"            
            echo ""
            exit 1
        fi 
        rm ./tmp/${1}.mp4
        mv ./tmp/out.mp4 ./tmp/${1}.mp4
        rm ./tmp/${1}.srt
    fi
    
}

