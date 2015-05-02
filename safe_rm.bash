# /bin/bash

function performDelete(){
	#Create recycle bin alias for files, move files to be deleted into recycle bin, and update .restore.info with their original full paths
	local fileName=${1##*/}
	local iNum=$(ls -li $1 | grep -v ^t | cut -d" " -f1)
	local iFile=$fileName"_"$iNum
	mv $(readlink -f $1) $HOME/deleted/$iFile
	echo "$iFile:$(readlink -f $1)" >>$HOME/.restore.info
	if [ $verbose = true ]
	then
		echo "$1 has been deleted."
	fi
}

function checkFileType(){
	#Check that each arguement passed is a file or a directory
	for i in $*
	do
		if [ -f $i ]
		#Files can simply be sent to the delete function
		then
			if [ $(readlink -f $i) = $HOME/project/safe_rm ]
			then
				echo "Attempting to delete safe_rm - operation aborted."
			else
				if [ $interactive = true ]
				then
					read -p "Are you sure you want to delete "$i"?(y/n)" opt
					if [ $opt = "Y" ] || [ $opt = "y" ]
					then
						performDelete $i
					elif [ $opt = "N" ] || [ $opt = "n" ]
					then
						echo "File "$i" not deleted."	
					else
						echo "Error: Invalid response."
					fi
				else
					performDelete $i
				fi
			fi
		elif [ -d $i ]
		#Directories must go to a separate function to extract the files then send the individual files to the delete function
		then
			if [ $recursive = true ]
			then
				performDirectoryDelete $i
			else
				echo "Error: Directories can only be deleted by safe_rm if the -r option is set."	
			fi
		else
			echo "Filename "$i" not found."
		fi
	done	
}

function performDirectoryDelete(){
	#Delete all files in directory, log it in .restore.info, then delete it
	#call to checkFileType will also ensure any subdirectories are deleted and stored
	local files=$(find $1 -maxdepth 1 -mindepth 1)
	local dirPath=$(readlink -f $1)
	for i in $files
	do
		#send full directory path to checkFileType so the files can be extracted and removed
		checkFileType $i
	done	

	#Now that the directory is empty, remove the directory
	if [ $interactive = true ]
	then
		read -p "Are you sure you want to delete directory "$1"?(y/n)" opt
			if [ $opt="y" ] || [ $opt="Y" ]
			then
				rmdir $dirPath
				if [ $verbose = true ]
				then
					echo "Deletion of "$1" successful"
				fi
			elif [ $opt="n" ] || [ $opt="N" ]
			then
				echo "Directory "$1" will not be deleted."
			else
				echo "Error: Invalid response."
			fi
	else			
		rmdir $dirPath
		if [ $verbose = true ]
		then
			echo "Deletion of "$1" successful"
		fi
	fi
}

function checkForRecycleBin(){
	#Check that both the deleted directory and the .restore.info file exist
	#If the files do not exist, create them
	local var=$HOME/deleted
	if [ ! -d $var ]
	then	
		mkdir deleted
		mv deleted ~
	fi

	local var2=$HOME/.restore.info
	if [ ! -e $var2 ]
	then
		touch .restore.info
		mv .restore.info ~
	fi
}

#---------------MAIN-----------------
#Options
#-v - provide confirmation messages
#-i - prompt for user confirmation
#-r - recursive deletion from directory

interactive=false
verbose=false
recursive=false

while getopts :vir OPTION
do
	case $OPTION in
		v)
			verbose=true ;;
		i)
			interactive=true ;;
		r)
			recursive=true ;;
		ri)
			recursive=true
			interactive=true ;;
		rv)
			recursive=true
			verbose=true ;;
		iv)
			interactive=true
			verbose=true ;;
		rvi)
			recursive=true
			interactive=true
			verbose=true ;;
		*)
			echo "Error: invalid option. safe_rm only supports -r, -v, and -i options."
			exit 1 ;;
	esac
done

shift $[$OPTIND-1]

if [ $# -eq 0 ]
#If no arguements provided, terminate script
then
	echo "Error: No filenames have been provided for deletion."
else
	#Make sure recycle bin and restore info exist
	checkForRecycleBin
	#handle items to be deleted
	checkFileType $*
fi
