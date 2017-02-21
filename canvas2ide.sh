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
elif [ "$#" -eq 3 ]; then
	input="$1"
	output="$2"
	check="$3"
elif [ "$#" -ge 3 ]; then
	echo "Arguments beyond third are ignored"
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
			if [[ ! -z $check && "$check".zip != "${zipfile##*/}" ]]; then
				#checking for canvas's garbo in particular
				if [[ ! "${zipfile##*/}" =~ "$check"-[0-9].zip ]]; then
					echo "$dir zipfile seems malformatted: Expected: $check.zip, Received: ${zipfile##*/}"
				fi
			fi
			unzip -qq "$zipfile" -d "$dir"
			rm "$zipfile"
			mkdir "$dir/$tmpstr"
			#using wildcard here since many don't match $zipfile, even with regex
			if [[ ! -z $check && ! -d "$dir/$check/src/" ]]; then
				echo "$dir project seems malformatted: $check project does not exist"
				for f in "$dir"/*; do
					if [[ -d "$f" && "$f" != *$tmpstr* ]]; then
						echo "did find possible project: $f"
					elif [[ "$f" != *$tmpstr* ]]; then
						echo "did find file: $f"
					fi	
				done
			fi
			mv "$dir"/*/src/* "$dir/$tmpstr" >> mv.log 2>&1
			#this will find any loose java files. the rest should already be in the src folder
			mv "$dir/"*.java "$dir/$tmpstr" >> mv.log 2>&1
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
