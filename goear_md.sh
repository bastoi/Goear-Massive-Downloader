#!/bin/bash

#
# Created by: Joel Badia Escolà (bastoigm@gmail.com)
# Released under GPLv3 (see more at http://www.gnu.org/licenses/gpl-3.0.html)
#
# Version: 0.0.1
#

# Download music massively from goear.com, it's your responsibility the usage that you make of this script.
#
# ENJOY IT !
#


#function definitions and global vars definition
FILE=

function help_message {
    cat <<EOF 
goear [args] urls_file

     options:
       -h: this help message
       -u url: download only this url
       -i: enter to interactive mode, search & download in the application
EOF
}

function show_options {
    cat <<EOF
Options:
   h -> shows this help message
   s song_name -> search this song
   q -> quit
EOF
}

function get_song {
    fileid=`echo $1 | cut -d '/' -f 5`
    xmlurl="http://www.goear.com/tracker758.php?f="$fileid
    infoline=`wget -qO- $xmlurl | grep ".mp3"`
    mp3url=`echo $infoline | cut -d '"' -f6`
    artist=`echo $infoline | cut -d '"' -f10`
    title=`echo $infoline | cut -d '"' -f12`
    wget $mp3url -O "$artist-$title.mp3"
}

function search_song {
    # $song not formated !!!
    song=`echo $1 | awk '{gsub(/\ /, "-"); lower_string = tolower($0); print lower_string}'`
    results=`wget -qO- www.goear.com/search/$song | grep "<li >"`

    if [ -z "$results" ]; then
	echo ""
    else
	# Get all the logic urls to possible songs with one search
	songs=`echo $results | awk '{

        html_info = $0
        while (index(html_info, "href=\"") != 0) {
            // href code
            start = index(html_info, "href=\"") + length("href=\"")
            html_info = substr(html_info, start)
            end = index(html_info, "\"")
            href = substr(html_info, 0, end - 1)

            // song name code
	    start = index(html_info, "class=\"song\">") + length("class=\"song\">")
	    html_info = substr(html_info, start)
	    end = index(html_info, "</")
	    song = substr(html_info, 0, end - 1)
	    gsub(/\ /, "_", song)

            // group code
            start = index(html_info, "class=\"group\">") + length("class=\"group\">")
	    html_info = substr(html_info, start)
	    end = index(html_info, "</")
	    group = substr(html_info, 0, end - 1)
	    gsub(/\ /, "_", group)

            // length code
	    start = index(html_info, "class=\"length\">") + length("class=\"length\">")
	    html_info = substr(html_info, start)
	    end = index(html_info, "</")
	    song_len = substr(html_info, 0, end - 1)

	    options[href] = href " " song " " group " " song_len
        }
    }
    END {for (option in options) {
		printf "%s ", options[option]
	    }
	    printf "\n"
	    }'`
	echo "$songs"
    fi
}

function command_parser() {
    case $1 in
	s)
	    echo "search song, not yet implemented"
	    printf "Enter song name: "
	    read song
	    song_meta=`search_song "$song"`
	    if [ -z "$song_meta" ]; then
		echo "Song not found"
	    else
		echo "Select some source"
		song_meta=( $song_meta )
		declare -A song_dict
		SONGS_LIST=
		total_words=`echo ${song_meta[@]} | wc -w`
		for i in `seq 0 4 $(( total_words-1 ))`; do
		    SONGS_LIST=`echo $SONGS_LIST ${song_meta[i+1]}-${song_meta[i+2]}-${song_meta[i+3]}`
		done

		SONGS_LIST="$SONGS_LIST Quit"
		
		select SONG in $SONGS_LIST; do
		    #get_song "http://www.goear.com/"${song_meta[(( ($REPLY-1)*4 ))]}
		    case $SONG in
			"Quit")
			    break
			    ;;
			*)
			   get_song "http://www.goear.com/"${song_meta[(( ($REPLY-1)*4 ))]}
			   ;;
		    esac
		done
	    fi
	    ;;
	h)
	    show_options
	    ;;
	?)
	    echo "Unknown option"
	    show_options
	    ;;
    esac
}

function interactive_m {
    IMS=" > "
    cat <<EOF
Welcome to Goear Massive Downloader interactive mode !!!
Developed by: Joel Badia Escolà

  Type h, for a list of commands.

ENJOY IT !

EOF
    printf $IMS
    read input
    while [ "$input" != "q" ]; do
	command_parser "$input"
	printf $IMS
	read input
    done
    echo "bye!"
}

# Read arguments and prepare strategy !!!
while getopts "hu:i" opt
do
    case $opt in
	h)
	    help_message;
	    exit 0;
	    ;;

	u)
	    get_song $OPTARG
	    exit 0;
	    ;;
	i)
	    echo "Interactive mode ON !"
	    interactive_m
	    exit 0;
	    ;;
	?)
	    cat <<EOF 

WARNING !!!

Unrecognized option: -$OPTARG

EOF
	    help_message;
	    exit -2
	    ;;
    esac
done

#Test if it has an existing file
val=${#@}
if [ $val -gt 0 ]
then
    declare -a args=("$@")
    FILE=${args[val-1]}
else
    echo "Error incorrect arguments"
    help_message
fi

if [ ! -e $FILE ]
then
    echo "Non existing urls_file";
    exit -3;
fi


#Read de different urls putted in a line by line url file
if [ ! -z $FILE ]
then
    DONE=false
    until $DONE
    do
	read line || DONE=true;
	if [ -n "$line" ]
	then
	    get_song $line;
	fi

	done < $1
fi
