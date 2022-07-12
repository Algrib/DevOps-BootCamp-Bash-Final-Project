#!/bin/bash

currentVersion="1.23.0"

httpSingleUpload()
{
   upResponse=$(curl --upload-file "$1" "https://transfer.sh/$2") #|| echo "Failure!"; return 1;
   echo "$upResponse"
}

singleUpload()
{
  filePath=$(echo "$1" | sed s:"~":"$HOME":g)
  if [[ ! -f "$filePath" ]]
  then
   echo "Error: invalid file path"
   return 1
  fi
  tempFileName=$(echo "$1" | sed "s:.*/::")
  echo "Uploading $tempFileName"
  httpSingleUpload "$filePath" "$tempFileName"
}

singleDownload()
{
 dirPath=$(echo "$1" | sed 's:/*$::')
 if [[ ! -d "$dirPath" ]]
 then
  echo "Non-existent save path, creating directory..."
  mkdir -p "$dirPath"
 fi

 if [[ -f "$dirPath/$3" ]]
 then
  echo "File already exists. Do you want to overwrite it? Path $1/$3. [y/n]"
  read -r input

  if [[ "$input" == [Yy] ]]
  then
   rm -f "$dirPath/$3"
  
  else
   echo "Download cancelled"; return 1;
  fi 
 fi
 echo "Downloading $3"
 downResponse=$(curl --progress-bar -o "$dirPath/$3" "https://transfer.sh/$2/$3") #|| { echo "Failure!"; return 1;}
 if [[ $? == 0 ]]
 then
  echo "$downResponse"
  echo "Success"
 fi
}

helpage()
{
 cat <<EOF
Description: Bash tool to transfer files from the command line.
Usage:
  -d  download single file to the specified directory.
  -h  Show the help ... 
  -v  Get the tool version
Examples:
Upload multiple files:

./transfer.sh test.txt test.txt test2.txt

Download from transfer.sh/<ID>. Scriptname <save-path> <ID> <file-name> :

./transfer.sh -d ./test Mij6ca test.txt
EOF
}

flag_check()
{
 # Check if $1 is a flag; e.g. "-b"
 [[ "$1" =~ -.* ]] && return 0 || return 1
}

while getopts "vhd" opt; do
 case "$opt" in
  \?)
   echo "Invalid option, use -h for help"
   exit 1 
   ;;
  d)
   # $OPTIND has the index of the _next_ parameter; so "\${$((OPTIND))}"
   # will give us, e.g., ${2}. Use eval to get the value in ${2}.
   # The {} are needed in general for the possible case of multiple digits.
   savePath="$((OPTIND))"
   remoteID="$((OPTIND+1))"
   remoteFileName="$((OPTIND+2))"
   # Note: We need to check that we're still in bounds, and that
   # a1,a2,a3 aren't flags. e.g.
   #   ./getopts-multiple.sh -a 1 2 -b
   # should error, and not set a3 to be -b.
   if [ $((OPTIND+2)) -gt $# ] || flag_check "$savePath" || flag_check "$remoteID" || flag_check "$remoteFileName"
   then
    echo "-d requires 3 arguments!"
   exit
   fi
   singleDownload "$savePath" "$remoteID" "$remoteFileName" || exit 1
  ;;
  h)
   helpage
  ;;
  v)
   echo "$currentVersion"
  ;;
 esac
done

if [[ $# -eq 0 ]]
then
 helpage
 exit 0

elif [[ -f "$1" ]]
then
 for i in "$@"
 do
  singleUpload "$i" || exit 1
  #printUploadResponse
 done
 exit 0
fi
