#!/bin/bash

#
# Created by: Joel Badia Escolà (bastoigm@gmail.com)
# Released under GPLv3 (see more at http://www.gnu.org/licenses/gpl-3.0.html)
#
# Version: 0.0.1
#

# Download massively music from goear.com, it's your responsability the usage
# that you make with this script.
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

function help_i_mode {
    cat <<EOF
Options:
   h -> shows this help message
   s song_name -> search this song
EOF
}

function get_song {
    #$1 = url

    fileid=`echo $1 | cut -d '/' -f 5`
    xmlurl="http://www.goear.com/tracker758.php?f="$fileid
    infoline=`wget -qO- $xmlurl | grep ".mp3"`
    mp3url=`echo $infoline | cut -d '"' -f6`
    artist=`echo $infoline | cut -d '"' -f10`
    title=`echo $infoline | cut -d '"' -f12`
    wget $mp3url -O "$artist-$title.mp3"
}

function command_parser() {
    case $1 in
	s)
	    echo "search song, not yet implemented"
	    ;;
	h)
	    help_i_mode
	    ;;
	?)
	    echo "Unknown command"
	    help_i_mode
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
	command_parser $input
	printf $IMS
	read input
    done
    # 
    #results=`wget -qO- www.goear.com/search/manel-aniversari | grep "<li >"`
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
