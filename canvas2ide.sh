#This is a simple script to (hopefully) robustly extract what canvas provides and extract it into the src folder of a single project
#This can be used however you want, though I will be using it/updating it assuming you create an eclipse project and and call that project's src folder as the target. 
#Importantly, I will be using a separate project for each run of the program, though it could potentially work without that
#After running this, run fix-packages.py to edit the source files and change the package declarations

#Author: Jeremy Cole


if [ "$#" -lt 2 ]; then
	echo "Please specify the location of the submissions zip and the output src folder"
	exit 1
elif [ "$#" -eq 2 ]; then
	input="$1"
	output="$2"
elif [ "$#" -ge 2 ]; then
	echo "Arguments beyond second are ignored"
	input="$1"
	output="$2"
fi 
inname="${input##*/}"
if [[ "$inname" != *.zip ]]; then
	echo "$input"" is not a zip file, so it's unlikely to be a submissions zip file"
	exit 2
fi
if [[ "$output" != *src* || ! -d "$output" ]]; then
	echo "Please specify a src folder to extract directly to, rather than: $output"
	exit 3
fi
#okay, first step is to unzip our input into our output... then proceed to do everything else!
unzip -qq "$input" -d "$output"

#make directories for each person
for f in "$output"/*; do
	fin="${f##*/}"
	name="${fin%%_*}"
	if [ ! -d "$output/$name" ]; then
		mkdir "$output/$name"
	fi
done
#move that person's files to the directory
for f in "$output"/*; do
	if [ -d "$f" ]; then
		continue
	fi
	fin="${f##*/}"
        name="${fin%%_*}"
	mv "$f" "$output/$name/"
done
#unzip files in that person's directory
tmpstr="tmpasdfadfssd" #just so it doesn't match anything else
for dir in "$output"/*; do
	if [ ! -d $dir ]; then
		continue
	fi
	#remove canvas naming garbage
	for garbF in "$dir"/*; do
		garbFName="${garbF##*/}"
		cleanFName="${garbFName##*_}"
		mv "$garbF" "$dir/$cleanFName"
	done
	#this part is tricky, because it doesn't very well handle zip files that were just PART of a submission
	#In this case structure is erased, and all files are stored flat
	for zipfile in "$dir"/*".zip"; do
		#can do matching here to a cmd line arg and a regex to ensure correct naming
		if [ -f "$zipfile" ]; then
			unzip -qq "$zipfile" -d "$dir"
			rm "$zipfile"
			mkdir "$dir/$tmpstr"
			#using wildcard here since many don't match $zipfile, even with regex
			mv "$dir"/*/src/* "$dir/$tmpstr"
			#this will find any loose java files. the rest should already be in the src folder
			mv "$dir/"*.java "$dir/$tmpstr"
		fi
	done
	for file in "$dir"/*; do
		if [[ $file != *$tmpstr* ]]; then
			#echo "$file"
			rm -r "$file"
		fi
	done
	for file in "$dir/$tmpstr/"*; do
		mv "$file" "$dir/"
	done
	rmdir "$dir/$tmpstr"
done
