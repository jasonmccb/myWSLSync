#!/bin/bash

folderList=(
	#"Melanie"
	#"Cathy"
	#"books"
	#"cameras/Huawei Mate8"
	#"cameras/Wei Xin"
	#"credentials 证件"
	#"entertainment"
	#"going abroad/NZ"
	#"JekyllBlog"
	#"jobs"
	#"modernLife"
	#"programming"
	#"English"
	#"installation"
	#"miscellanies"
	#"mobilePhone"
	#"pc knowledge"
)

findExcludePatternList=(
	### Ignores self containing folder
	"*/programming/bash/myWSLSync/*"
	### Ignores folders and files started with '.'
	"*/.git*"
	"*/.vs*"
	"*/.jekyll*"
	### Ignores specific big folders or files
	#"*/programming/VC_Cpp/Qt_5.12/*"
	#"*/programming/JAVA/*/*"
	#"*/programming/Ruby/Ruby192/*"
	#"*/programming/python/Python/Python38-32/*"
	#"*/going abroad/NZ/study/*"
	#"*/books/novel/*"
	#"*/Cathy/marriage/*"
	#"*/entertainment/games/SC/*"
	#"*/entertainment/games/steam/*"
	#"*/entertainment/stories/*"
	#"*/AlbumArt_*_*.jpg"
	#"*/jobs/nti/*"
	#"*/qt-opensource-windows-x86-5.12.0.exe"
)

rsyncGlobalExcludePatternList=(
	### Ignores self containing folder
	"**/bash/myWSLSync/**"
	### Ignores folders and files started with '.'
	"**/.git**"
	"**/.vs**"
	"**/.jekyll**"
	### Ignores specific big folders or files
	#"**/VC_Cpp/Qt_5.12/**"
	#"**/JAVA/*/**"
	#"**/Ruby/Ruby192/**"
	#"**/python/Python/Python38-32/**"
	#"**/study/**"
	#"**/novel/**"
	#"**/marriage/**"
	#"**/games/SC/**"
	#"**/games/steam/**"
	#"**/stories/**"
	#"AlbumArt_*_*.jpg"
	#"**/nti/**"
	#"qt-opensource-windows-x86-5.12.0.exe"
)

sourceDrive="d"
targetDrive="e"
sourceDirBase="/mnt/${sourceDrive}"
targetDirBase="/mnt/${targetDrive}"
logFileName="myWSLSync."`date +%Y%m%d`".log"
# To make real copy actions, set dryRun to 0
dryRun=1
rsyncExcludeRules=""
findExcludePathPatterns=''
for (( i = 0; i < ${#findExcludePatternList[@]}; i++ ))
do
	findExcludePathPatterns=$findExcludePathPatterns'! -path "'${findExcludePatternList[i]}'" '
done
for (( i = 0; i < ${#rsyncGlobalExcludePatternList[@]}; i++ ))
do
	rsyncExcludeRules="$rsyncExcludeRules --exclude='${rsyncGlobalExcludePatternList[i]}'"
done


function errPromptExit()
{	echo "An error has occured. Press Y to continue, any other key to exit..."
	read -n 1 char
	echo
	[ "$char" != "Y" -a "$char" != "y" ] && { echo "Err EXIT" >> "$logFileName"; exit 1;}
}

function promptExit()
{	echo "Press any key to continue, N to quit..."
	read -n 1 char
	echo
	[ "$char" = "N" -o "$char" = "n" ] && { echo "QUIT" >> "$logFileName"; exit 0;}
}

function mountDrive()
{	if [ $# -ge 2 ]; then
		driveID="$1"
		mountDir="$2"
		ls "$mountDir" &> /dev/null
		if [ "$?" != "0" ]; then sudo mkdir "$mountDir"; fi
		[ "$?" != "0" ] && errPromptExit
		if [ `ls "$mountDir" |wc -l` -le 0 ]; then
			sudo mount -t drvfs "${driveID^^}:" $mountDir;
			if [ "$?" != "0" ]; then
				errPromptExit
			else
				echo "Success." |tee -a "$logFileName"
			fi
		else
			echo "No need." |tee -a "$logFileName"
		fi
		return 0
	else
		return 1
	fi
}

echo `date` >> "$logFileName"
echo '==== Mounting source drive ====' |tee -a "$logFileName"
mountDrive "$sourceDrive" "$sourceDirBase"
echo '==== Mounting target drive ====' |tee -a "$logFileName"
mountDrive "$targetDrive" "$targetDirBase"

# Use for loop with index to avoid space globbing in folder names
for (( i = 0; i < ${#folderList[@]}; i++ ))
do
	sourceDir="${sourceDirBase}/${folderList[i]}"
	targetDir="${targetDirBase}/${folderList[i]}"
	
	echo '==== Adding read and write permissions ====' |tee -a "$logFileName"
	#subDirsNoRead=`find "${sourceDir}" -maxdepth 1 -type d \! -name ".*" \! -perm /444 -printf "\"%p\"\n"`
	subDirsNoRead=`echo 'find "'$sourceDir'" -maxdepth 1 -type d '$findExcludePathPatterns' ! -perm /444 -printf "\"%p\"\n"' |sh`
	if [ "$subDirsNoRead" != "" ]; then
		echo "$subDirsNoRead" >> "$logFileName"
		echo "$subDirsNoRead" |xargs sudo chmod -R a+r,a+x
		[ "$?" != "0" ] && errPromptExit
	fi
	#subDirsNot777=`find "${targetDir}" -maxdepth 1 -type d \! -name ".*" \! -perm 777 -printf "\"%p\"\n"`
	subDirsNot777=`echo 'find "'$targetDir'" -maxdepth 1 -type d '$findExcludePathPatterns' ! -perm 777 -printf "\"%p\"\n"' |sh`
	if [ "$subDirsNot777" != "" ]; then
		echo "$subDirsNot777" >> "$logFileName"
		echo "$subDirsNot777" |xargs sudo chmod -R 777
		[ "$?" != "0" ] && errPromptExit
	fi

	echo '==== Below folders from "'${sourceDir}'" will be copied. ====' |tee -a "$logFileName"
	sourceChildrenDirs=`echo 'find "'$sourceDir'" -maxdepth 1 -type d '$findExcludePathPatterns'-printf "%f\n"' |sh |sort`
	targetChildrenDirs=`echo 'find "'$targetDir'" -maxdepth 1 -type d '$findExcludePathPatterns'-printf "%f\n"' |sh |sort`
	newChildrenFolders=`comm -23 <(echo "$sourceChildrenDirs") <(echo "$targetChildrenDirs")`
	if [ "$newChildrenFolders" != "" ]; then
		echo "$newChildrenFolders" |tee -a "$logFileName"
		promptExit
	fi
	
	echo "==== Copying ====" |tee -a "$logFileName"
	if [ $dryRun -eq 0 ]; then
		#rsync -avur --exclude='*/.*' "${sourceDir}/" "${targetDir}"  |& tee -a "$logFileName"
		echo 'rsync -avur --delete '$rsyncExcludeRules' "'$sourceDir'/" "'$targetDir'"' |sh |& tee -a "$logFileName"
		[ "$?" != "0" ] && errPromptExit
	else
		#rsync -navur --exclude='*/.*' "${sourceDir}/" "${targetDir}"  |& tee -a "$logFileName"
		echo 'rsync -navur --delete '$rsyncExcludeRules' "'$sourceDir'/" "'$targetDir'"' |sh  |& tee -a "$logFileName"
		[ "$?" != "0" ] && errPromptExit
	fi
	
	echo "==== Difference after the copy ====" |tee -a "$logFileName"
	# Blindedly find the difference
	# comm -3 <(find "${sourceDir}" -maxdepth 1 -type d -printf "%f\n" |sort) <(find "${targetDir}" -maxdepth 1 -type d -printf "%f\n" |sort)
	# comm -3 <(find "${sourceDir}" -type f -printf "%f\n" |sort) <(find "${targetDir}" -type f -printf "%f\n" |sort)
	
	# Compare folders first
	#sourceSubDirs=`find "${sourceDir}" -type d \! -path "*/.*" -printf "%p\n" |awk -v base="$sourceDirBase" '{print substr($0,length(base)+2)}' |sort`
	sourceSubDirs=`echo 'find "'$sourceDir'" -type d '$findExcludePathPatterns' -printf "%p\n"' |sh |awk -v base="$sourceDirBase" '{print substr($0,length(base)+2)}' |sort`
	[ "$?" != "0" ] && errPromptExit
	#targetSubDirs=`find "${targetDir}" -type d \! -path "*/.*" -printf "%p\n" |awk -v base="$targetDirBase" '{print substr($0,length(base)+2)}' |sort`
	targetSubDirs=`echo 'find "'$targetDir'" -type d '$findExcludePathPatterns' -printf "%p\n"' |sh |awk -v base="$targetDirBase" '{print substr($0,length(base)+2)}' |sort`
	[ "$?" != "0" ] && errPromptExit
	dirs1=`comm -23 <(echo "$sourceSubDirs") <(echo "$targetSubDirs")`
	dirs1Shortest=`echo "$dirs1" |awk 'BEGIN{currentShortestDir=""}
		(NR==1){currentShortestDir=$0;print}
		(NR>1){ if (index ($0, currentShortestDir) == 0)
				{currentShortestDir=$0;print}
			}'`
	dirs2=`comm -13 <(echo "$sourceSubDirs") <(echo "$targetSubDirs")`
	dirs2Shortest=`echo "$dirs2" |awk 'BEGIN{currentShortestDir=""}
		(NR==1){currentShortestDir=$0;print}
		(NR>1){ if (index ($0, currentShortestDir) == 0)
				{currentShortestDir=$0;print}
			}'`
	dirs3=`comm -12 <(echo "$sourceSubDirs") <(echo "$targetSubDirs")`
	files1=""
	files2=""
	while read line
	do
		[ "$line" = "" ] && continue
		linePercentSymbolConverted=`echo "$line" |sed 's/%/%%/g'`
		sourceChildrenFiles=`echo 'find "'$sourceDirBase'/'$line'" -maxdepth 1 -type f '$findExcludePathPatterns'-printf "'$linePercentSymbolConverted'/%f\n"' |sh |sort`
		targetChildrenFiles=`echo 'find "'$targetDirBase'/'$line'" -maxdepth 1 -type f '$findExcludePathPatterns'-printf "'$linePercentSymbolConverted'/%f\n"' |sh |sort`
		diff1=`comm -23 <(echo "$sourceChildrenFiles") <(echo "$targetChildrenFiles")`
		diff2=`comm -13 <(echo "$sourceChildrenFiles") <(echo "$targetChildrenFiles")`
		[ "$diff1" != "" ] && files1="$files1\n$diff1"
		[ "$diff2" != "" ] && files2="$files2\n$diff2"
	done < <(echo "$dirs3")
	
	echo "-===Failed to copy:" |tee -a "$logFileName"
	echo "$dirs1Shortest" |tee -a "$logFileName"
	echo -e "$files1" |tee -a "$logFileName"
	echo "-===Extra folders/files:" |tee -a "$logFileName"
	echo "$dirs2Shortest" |tee -a "$logFileName"
	echo -e "$files2" |tee -a "$logFileName"
	echo >> "$logFileName"
done



