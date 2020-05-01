#!/bin/bash
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
folders=$(find "${lidarr_artist_path}" -mindepth 1 -maxdepth 1 -type d '!' -exec test -e "{}/folder.jpg" ';' -print)
for folder in ${folders}
do
	foldername="$(basename "$folder")"
	file=$(find "${folder}" -iregex ".*/.*\.\(flac\|mp3\|opus\|m4a\)" | head -n 1)
	if [ ! -z "$file" ]; then
		artwork="$(dirname "$file")/folder.jpg"
		if ffmpeg -i "$file" -c:v copy "$artwork" 2>/dev/null; then
			echo "SUCCESS: Artwork Extracted for: $foldername"
		else
			echo "ERROR: No artwork found for: $foldername"
		fi
	else
		continue
	fi
done
IFS=$SAVEIFS
