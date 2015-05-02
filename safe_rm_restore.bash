#! /bin/bash

function restoreFile(){
	#restorePath is the whole, full path of a deleted item
	#restoreDirPath is the path to the directory in which the deleted item should be stored
	local restorePath=$(grep $1 $HOME/.restore.info | cut -d":" -f2)
	local restoreDirPath=$(dirname $restorePath)
	if [ -e $restorePath ]
	#If a file exists with the same path, ask user for permission, then overwrite if yes
	then
		read -p "File currently exists. Do you want to overwrite?(y/n)" opt
		if [ $opt = "y" ] || [ $opt = "Y" ]
		then
			rm $restorePath
			mv $HOME/deleted/$1 $restorePath
			sed -e "/$1/d" $HOME/.restore.info >$HOME/.restore.info.temp ; mv $HOME/.restore.info.temp $HOME/.restore.info
		fi
	else
	#If the file doesn't exist, check if its home directory does. If it doesn't create it.
	#Loop steps through whole path, so even if multiple directories need to be restored it will work 
		i=2
		buildPath="/"
		until [ $buildPath = $restoreDirPath ]
		do
			buildPath=$(echo $restorePath | cut -d"/" -f-$i)
			if [ ! -d $buildPath ]
			then
				mkdir $buildPath
			fi

			((i++))
		done
		
		#Move deleted item back into appropriate directory
		local filename=$(echo $1 | cut -d"_" -f1)
		mv $HOME/deleted/$1 $buildPath/$filename
		sed -e "/$1/d" $HOME/.restore.info >$HOME/.restore.info.temp ; mv $HOME/.restore.info.temp $HOME/.restore.info
	fi
}

function checkFile(){
#Check if the requested file to restore is currently located in the recycle bin
	if [ -f $HOME/deleted/$1 ]
	then
		restoreFile $1
	else
		echo "Error: File does not exist."
	fi
}

#MAIN
if [ $# -eq 0 ]
then
	echo "Error: No filename provided"
	exit
else
	checkFile $1
fi
