#!/bin/bash
# export1
# export2
# export3
#####################################################################################################
#                                     Lidarr Automated Downloader                                   #
#                                       Credit: RandomNinjaAtk                                      #
#####################################################################################################
#                                           Script Start                                            #
#####################################################################################################

############ Import Script Settings
source ./config

configuration () {
	echo "######################################### CONFIGURATION VERIFICATION #########################################"
	error=0
	
	if [ $DownloadMode = Both ] || [ $DownloadMode = Audio ] || [ $DownloadMode = Video ]; then
		echo "Download Audio/Video: $DownloadMode"
	else
		echo "ERROR: DownloadMode setting invalid, currently set to: $DownloadMode"
		echo "ERROR: DownloadMode Expected Valid Setting: Both or Audio or Video"
		error=1
	fi
	
	if [ $DownloadMode = Both ] || [ $DownloadMode = Audio ]; then
		
		if [ "$VerifyTrackCount" = "true" ]; then
			vtc="Enabled"
		else
			vtc="Disabled"
		fi
		
		if [ "$ReplaygainTagging" = "TRUE" ]; then
			gain="Enabled"
		else
			gain="Disabled"
		fi

		if [ $ImportMode = match ] || [ $ImportMode = forced ] || [ $ImportMode = manual ]; then
			echo "Import Mode: $ImportMode"
		else
			echo "ERROR: ImportMode setting invalid, currently set to: $ImportMode"
			echo "ERROR: ImportMode Expected Valid Setting: match or forced or manual"
			error=1
		fi

		if [ $AudioMode = wanted ] || [ $AudioMode = archive ]; then
			echo "Audio Mode: $AudioMode"
		else
			echo "ERROR: AudioMode setting invalid, currently set to: $AudioMode"
			echo "ERROR: AudioMode Expected Valid Setting: wanted or archive"
			error=1
		fi
		
		if [ ! -z "$downloaddir" ]; then
			echo "Audio Download Path: $downloaddir"
		else
			echo "ERROR: downloaddir setting invalid, currently set to: $downloaddir"
			echo "ERROR: downloaddir Expected Valid Setting: /your/path/to/dlclient/downloads/folder"
			error=1
		fi
		
		if [ ! -z "$LidarrImportLocation" ]; then
			echo "Lidarr Temp Import Path: $LidarrImportLocation"
		else
			echo "ERROR: LidarrImportLocation setting invalid, currently set to: $LidarrImportLocation"
			echo "ERROR: LidarrImportLocation Expected Valid Setting: /your/path/to/temp/lidarr/import/folder"
			error=1
		fi
		
		if [ "$quality" = "OPUS" ]; then
			echo "Download Quality: $quality"
			echo "Download Bitrate: ${ConversionBitrate}k"
			extension="opus"
		elif [ "$quality" = "AAC" ]; then
			echo "Download Quality: $quality"
			echo "Download Bitrate: ${ConversionBitrate}k"
			extension="m4a"
		elif [ "$quality" = "FDK-AAC" ]; then
			echo "Download Quality: $quality"
			echo "Download Bitrate: ${ConversionBitrate}k"
			extension="m4a"
		elif [ "$quality" = "MP3" ]; then
			echo "Download Quality: $quality"
			echo "Download Bitrate: 320k"
			extension="mp3"
		elif [ "$quality" = "FLAC" ]; then
			echo "Download Quality: $quality"
			echo "Download Bitrate: lossless"
			extension="flac"
		else
			echo "ERROR: quality setting invalid, currently set to: $quality"
			echo "ERROR: quality Expected Valid Setting: OPUS or AAC or FDK-AAC or MP3 or FLAC"
			error=1
		fi
		echo "Download Track Count Verification: $vtc"
		if [ "$quality" = "FLAC" ]; then
			echo "Replaygain Tagging: $gain"
		fi
		if [ "$TagWithBeets" = "true" ]; then
			echo "Beets Tagging: Enabled"
		else
			echo "Beets Tagging: Disabled"
		fi
		if [ "$quality" != "MP3" ]; then
			dlquality="flac"
		else
			dlquality="128"
		fi
		beetsmatch="false"
	fi
	
	if [ $DownloadMode = Both ] || [ $DownloadMode = Video ]; then
		if [ ! -z "$VideoPath" ]; then
			echo "Video Download Path: $VideoPath"
		else
			echo "ERROR: VideoPath setting invalid, currently set to: $VideoPath"
			echo "ERROR: VideoPath Expected Valid Setting: /your/path/to/music/video/folder"
			error=1
		fi
	fi

	if [ $error = 1 ]; then
		echo "Please correct errors before attempting to run script again..."
		echo "Exiting..."
		exit 1
	fi
}

ImportFunction () {

	if [ ! -d "${LidarrImportLocation}/${importalbumfolder}" ]; then
		mkdir -p "${LidarrImportLocation}/${importalbumfolder}"
		for file in "$downloaddir"/*; do
			mv "$file" "${LidarrImportLocation}/${importalbumfolder}"/
		done
		FolderAccessPermissions "${LidarrImportLocation}/${importalbumfolder}"
		FileAccessPermissions "${LidarrImportLocation}/${importalbumfolder}"
	fi
	
	if [ "$ImportMode" = "match" ]; then
		if [ -d "${LidarrImportLocation}/${importalbumfolder}" ]; then
			LidarrProcessIt=$(curl -s "$LidarrUrl/api/v1/command" --header "X-Api-Key:"${LidarrApiKey} --data "{\"name\":\"DownloadedAlbumsScan\", \"path\":\"${LidarrImportLocation}/${importalbumfolder}\"}" );
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: IMPORT :: Notified Lidarr to scan \"${LidarrImportLocation}/${importalbumfolder}\" for import"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: IMPORT :: Notified Lidarr to scan \"${LidarrImportLocation}/${importalbumfolder}\" for import"
			fi
		fi
	elif [ "$ImportMode" = "forced" ]; then
		if [ ! -d "${LidArtistPath}" ]; then
			mkdir -p "${LidArtistPath}"
		fi
		mv "${LidarrImportLocation}/${importalbumfolder}" "$LidArtistPath/$libalbumfolder"
		FolderAccessPermissions "$LidArtistPath/$libalbumfolder"
		FileAccessPermissions "$LidArtistPath/$libalbumfolder"
		LidarrProcessIt=$(curl -s $LidarrUrl/api/v1/command -X POST -d "{\"name\": \"RescanFolders\", \"folders\": [\"$LidArtistPath/$libalbumfolder\"]}" --header "X-Api-Key:${LidarrApiKey}" );
		if [ $AudioMode = archive ]; then
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: IMPORT :: Notified Lidarr to scan $LidArtistPath/$libalbumfolder"
		fi
		if [ $AudioMode = wanted ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: IMPORT :: Notified Lidarr to scan $LidArtistPath/$libalbumfolder"
		fi
	elif [ "$ImportMode" = "manual" ]; then
		if [ $AudioMode = archive ]; then
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: IMPORT :: Album Saved for manual import: \"${LidarrImportLocation}/${importalbumfolder}\""
		fi
		if [ $AudioMode = wanted ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: IMPORT :: Album Saved for manual import: \"${LidarrImportLocation}/${importalbumfolder}\""
		fi
	fi
}

paths () {

	if [ ! -d "$downloaddir" ]; then
		mkdir -p "$downloaddir"
		FolderAccessPermissions "$downloaddir"
	fi
	
	if [ ! -d "$LidarrImportLocation" ]; then
		mkdir -p "$LidarrImportLocation"
		FolderAccessPermissions "$downloaddir"
	fi	
}

CleanDLPath () {
	if find "${downloaddir}" -type f | read; then
		echo "Cleaning Download directory..."
		find "${downloaddir}" -type f -delete
	fi
}

CleanImportPath () {
	if [ -f "cleanup-imports" ]; then
		rm "cleanup-imports"
	fi
	touch -d "3 hours ago" "cleanup-imports"
	if find "${LidarrImportLocation}" -type d -not -newer "cleanup-imports" | read; then
		echo "Cleaning Lidarr Import directory..."
		find "${LidarrImportLocation}" -type d -not -newer "cleanup-imports" -exec rm -rf "{}" \; > /dev/null 2>&1
	fi
	rm "cleanup-imports"
}

CleanCacheCheck () {
	if [ -d "cache" ]; then
		if [ -f "cleanup-cache-check" ]; then
			rm "cleanup-cache-check"
		fi
		touch -d "168 hours ago" "cleanup-cache-check"
		if find "cache" -type f -iname "*-checked" -not -newer "cleanup-cache-check" | read; then
			echo "Remvoing Cached Checked files older than 168 Hours..."
			find "cache" -type f -iname "*-checked" -not -newer "cleanup-cache-check" -delete
		fi
		if find "cache" -type f -iname "*-info.json" -not -newer "cleanup-cache-check" | read; then
			echo "Remvoing Cached Artist Info files older than 168 Hours..."
			find "cache" -type f -iname "*-info.json" -not -newer "cleanup-cache-check" -delete
		fi
		rm "cleanup-cache-check"
	fi
}


CleanMusicbrainzLog () {
	if [ -f "cleanup-musicbrainzerrorlog" ]; then
		rm "cleanup-musicbrainzerrorlog"
	fi
	if [ -f "cleanup-musicbrainzerrorlog" ]; then
		touch -d "3 hours ago" "cleanup-musicbrainzerrorlog"
		if find -type f -iname "musicbrainzerror.log" -not -newer "cleanup-musicbrainzerrorlog" | read; then
			echo "Cleaning  musicbrainzerror.log..."
			find find -type f -iname "musicbrainzerror.log" -not -newer "cleanup-musicbrainzerrorlog" -delete
		fi
		rm "cleanup-musicbrainzerrorlog"
	fi
}

CleanNotfoundLog () {
	if [ -f "cleanup-notfoundlog" ]; then
		rm "cleanup-notfoundlog"
	fi
	if [ -f "cleanup-notfoundlog" ]; then
		touch -d "168 hours ago" "cleanup-notfoundlog"
		if find -type f -iname "notfound.log" -not -newer "cleanup-notfoundlog" | read; then
			echo "Cleaning  notfound.log..."
			find find -type f -iname "notfound.log" -not -newer "cleanup-notfoundlog" -delete
		fi
		rm "cleanup-notfoundlog"
	fi
}

QualityVerification () {
	if [ "$quality" = "MP3" ]; then
		if find "$downloaddir" -iname "*.flac" | read; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: QUALITY VERIFICATION :: ERROR :: All tracks did not meet target quality.."
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: QUALITY VERIFICATION :: ERROR :: All tracks did not meet target quality.."
			fi
			CleanDLPath
		fi
	else
		if find "$downloaddir" -iname "*.mp3" | read; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: QUALITY VERIFICATION :: ERROR :: All tracks did not meet target quality.."
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: QUALITY VERIFICATION :: ERROR :: All tracks did not meet target quality.."
			fi
			CleanDLPath
		fi
	fi
}

FileAccessPermissions () {
	if [ $AudioMode = archive ]; then
		echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: PERMISSIONS :: Modifying Files in: $1 (${FilePermissions})..."
	fi
	if [ $AudioMode = wanted ]; then
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: PERMISSIONS :: Modifying Files in: $1 (${FilePermissions})..."
	fi
	chmod ${FilePermissions} "$1"/*
	# docker-chown-01
}


FolderAccessPermissions () {
	if [ $AudioMode = archive ]; then
		echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: PERMISSIONS :: Modifying Folder $1(${FolderPermissions})..."
	fi
	if [ $AudioMode = wanted ]; then
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: PERMISSIONS :: Modifying Folders $1 (${FolderPermissions})..."
	fi
	chmod ${FolderPermissions} "$1"
	# docker-chown-02
}

DurationCalc () {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days and ' $D
  (( $H > 0 )) && printf '%d:' $H
  (( $M > 0 )) && printf '%02d:' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf ''
  printf '%02ds\n' $S
}

beetstagging () {
	trackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
	if [ $AudioMode = archive ]; then
		echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: BEETS :: Matching $trackcount tracks with Beets"
	fi
	if [ $AudioMode = wanted ]; then
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: BEETS :: Matching $trackcount tracks with Beets"
	fi
	if [ -f "${BeetLibrary}" ]; then
		rm "${BeetLibrary}"
		sleep 0.1
	fi
	if [ -f "${BeetLog}" ]; then 
		rm "${BeetLog}"
		sleep 0.1
	fi
	
	touch "$downloaddir/beets-match"
	sleep 0.1
	
	if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
		beet -c "${BeetConfig}" -l "${BeetLibrary}" -d "$downloaddir" import -q "$downloaddir" &> /dev/null
		if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" -newer "$downloaddir/beets-match" | read; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: BEETS :: Matched with beets!"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: BEETS :: Matched with beets!"
			fi
			beetsmatch="true"
			TagFix
		else
			beetsmatch="false"
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: BEETS :: ERROR: Unable to match using beets, fallback to lidarr import matching..."
				if [ "$RequireBeetsMatch" = true ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: BEETS :: ERROR: RequireBeetsMatch enabled, performing cleanup"
					CleanDLPath
				fi
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: BEETS :: ERROR: Unable to match using beets, fallback to lidarr import matching..."
				if [ "$RequireBeetsMatch" = true ]; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: BEETS :: ERROR: RequireBeetsMatch enabled, performing cleanup"
					CleanDLPath
				fi
			fi
		fi	
	fi
	
	if [ -f "$downloaddir/beets-match" ]; then 
		rm "$downloaddir/beets-match"
		sleep 0.1
	fi
}

LidarrAlbums () {
	echo "######################################### DOWNLOAD AUDIO (WANTED MODE) #########################################"
	if [ -f "temp-lidarr-missing.json" ]; then
		rm "temp-lidarr-missing.json"
		sleep 0.1
	fi

	if [ -f "temp-lidarr-cutoff.json" ]; then
		rm "temp-lidarr-cutoff.json"
		sleep 0.1
	fi

	if [ -f "lidarr-monitored-list.json" ]; then
		rm "lidarr-monitored-list.json"
		sleep 0.1
	fi

	curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/wanted/missing/?page=1&pagesize=${amount}&includeArtist=true&monitored=true&sortDir=desc&sortKey=releaseDate" -o temp-lidarr-missing.json
	missingtotal=$(cat "temp-lidarr-missing.json"| jq -r '.records | .[] | .id' | wc -l)
	echo "FINDING MISSING ALBUMS: ${missingtotal} Found"
	if [ "$TrackUpgrade" = true ]; then
		curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/wanted/cutoff/?page=1&pagesize=${amount}&includeArtist=true&monitored=true&sortDir=desc&sortKey=releaseDate" -o temp-lidarr-cutoff.json
		cuttofftotal=$(cat "temp-lidarr-cutoff.json"| jq -r '.records | .[] | .id' | wc -l)
		echo "FINDING CUTOFF ALBUMS: ${cuttofftotal} Found"
	fi
	jq -s '.[]' temp-lidarr-*.json > "lidarr-monitored-list.json"
	wantit=$(cat "lidarr-monitored-list.json")
	wantitid=($(echo "${wantit}"| jq -r '.records | .[] | .id'))
	wantittotal=$(echo "${wantit}"| jq -r '.records | .[] | .id' | wc -l)

	if [ -f "temp-lidarr-missing.json" ]; then
		rm "temp-lidarr-missing.json"
		sleep 0.1
	fi

	if [ -f "temp-lidarr-cutoff.json" ]; then
		rm "temp-lidarr-cutoff.json"
		sleep 0.1
	fi

	if [ -f "lidarr-monitored-list.json" ]; then
		rm "lidarr-monitored-list.json"
		sleep 0.1
	fi

	if [ -z "$wantit" ]; then
		echo "ERROR: Cannot communicate with Lidarr"
		exit 1
	fi
}

ProcessLidarrAlbums () {
	
	for id in ${!wantitid[@]}; do
		currentprocess=$(( $id + 1 ))
		albumid="${wantitid[$id]}"
		wantitalbum=$(curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/album?albumIds=${albumid}")
		wantitalbumrecordtitles=($(echo "${wantitalbum}" | jq '.[] | .releases | .[] | .id'))
		
		if [ -z "$wantitalbum" ]; then
			echo "ERROR: Cannot communicate with Lidarr"
			exit 1
		fi
		
		# Get album information from lidarr
		wantitalbumtitle=$(echo "${wantitalbum}"| jq -r '.[] | .title')
		wantitalbumid=$(echo "${wantitalbum}"| jq -r '.[] | .id')
		wantitalbummbid=$(echo "${wantitalbum}"| jq -r '.[] | .foreignAlbumId')
		wantitalbumyear="$(echo "${wantitalbum}"| jq -r '.[] | .releaseDate')"
		wantitalbumyear="${wantitalbumyear:0:4}"
		wantitalbumtrackcount=$(echo "${wantitalbum}"| jq -r '.[] | .statistics.trackCount')
		wantitalbumalbumType=$(echo "${wantitalbum}"| jq -r '.[] | .albumType')
		wantitalbumartistname=$(echo "${wantitalbum}"| jq -r '.[] | .artist.artistName')
		wantitalbumartisid=$(echo "${wantitalbum}"| jq -r '.[] | .artist.id')
		wantitalbumartispath=$(echo "${wantitalbum}"| jq -r '.[] | .artist.path')
		LidArtistPath="$wantitalbumartispath"
		LidArtistNameCap="$wantitalbumartistname"
		sanatizedartistname="$(echo "${LidArtistNameCap}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
		wantitalbumartistmbid=$(echo "${wantitalbum}"| jq -r '.[] | .artist.foreignArtistId')
		lidarralbumartistmbrainzid=${wantitalbumartistmbid}
		wantitalbumartistdeezerid=($(echo "${wantitalbum}"| jq -r '.[] | .artist.links | .[] |  select(.name=="deezer") | .url'))
		normalizetype="${wantitalbumalbumType,,}"
		sanatizedwantitalbumtitle="$(echo "$wantitalbumtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
		sanatizedwantitartistname="$(echo "${wantitalbumartistname}" | sed -e "s/’/ /g" -e "s/'/ /g" -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
		sanatizedwantitalbumtitlefuzzy="$(echo "$wantitalbumtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
		sanatizedwantitalbumtitlefuzzy="${sanatizedwantitalbumtitlefuzzy// /%20}"
		sanatizedwantitalbumartistnamefuzzy="$(echo "${wantitalbumartistname}" | sed -e "s/’/ /g" -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
		sanatizedwantitalbumartistnamefuzzy="${sanatizedwantitalbumartistnamefuzzy// /%20}"
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: LIDARR :: Album ID: $wantitalbummbid"
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: LIDARR :: Album Year: $wantitalbumyear"
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: LIDARR :: Album Type: $normalizetype" 
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: LIDARR :: Album Track Count: $wantitalbumtrackcount"
		if [ "$wantitalbumartistname" != "Various Artists" ]; then
			if [ -z "${wantitalbumartistdeezerid}" ]; then	
				if [ -f "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch" ]; then
					wantitalbumartistdeezerid="$(cat "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch")"
					
					if ! [ -f "musicbrainzerror.log" ]; then
						touch "musicbrainzerror.log"
					fi
					if cat "musicbrainzerror.log" | grep "${wantitalbumartistmbid}" | read; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Using cached fuzzymatch for processing this request... update musicbrainz id: ${wantitalbumartistmbid} with missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
					else
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Using cached fuzzymatch for processing this request... update musicbrainz id: ${wantitalbumartistmbid} with missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
						echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/${wantitalbumartistmbid}/relationships for \"${wantitalbumartistname}\" with Deezer Artist Link" >> "musicbrainzerror.log"
					fi
				fi			
			elif [ -f "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch" ]; then
				rm "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch"
			fi
			
			# Get Deezer ArtistID from Musicbrainz if not found in Lidarr
			if [ -z "${wantitalbumartistdeezerid}" ]; then	
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: Fallback to musicbrainz for url..."
				mbjson=$(curl -s "${musicbrainzurl}/ws/2/artist/${wantitalbumartistmbid}?inc=url-rels&fmt=json")
				wantitalbumartistdeezerid=($(echo "$mbjson" | jq -r '.relations | .[] | .url | select(.resource | contains("deezer")) | .resource'))		
			fi	
			
			# If Deezer ArtistID is not found, log it...
			if [ -z "$wantitalbumartistdeezerid" ]; then
			
				if ! [ -f "musicbrainzerror.log" ]; then
					touch "musicbrainzerror.log"
				fi
				if cat "musicbrainzerror.log" | grep "${wantitalbumartistmbid}" | read; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: \"${wantitalbumartistname}\"... musicbrainz id: ${wantitalbumartistmbid} is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
					albumfuzzy=$(curl -s "https://api.deezer.com/search?q=artist:%22$sanatizedwantitalbumartistnamefuzzy%22%20album:%22$sanatizedwantitalbumtitlefuzzy%22")
					wantitalbumartistdeezeridfuzzy=($(echo "$albumfuzzy" | jq ".data | .[] | .artist.id" | sort -u))
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Attemtping fuzzy search for Artist: $wantitalbumartistname :: Album: $wantitalbumtitle"
					for id in "${!wantitalbumartistdeezeridfuzzy[@]}"; do
						currentprocess=$(( $id + 1 ))
						fuzzyaritstid=${wantitalbumartistdeezeridfuzzy[$id]}
						fuzzyaritstname="$(echo "$albumfuzzy" | jq ".data | .[] | .artist | select(.id==$fuzzyaritstid) | .name" | sort -u | sed -e "s/’/ /g" -e "s/'/ /g" -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
						if [ "$sanatizedwantitartistname" = "$fuzzyaritstname" ]; then
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Match found!"
							touch "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch"
							echo "$fuzzyaritstid" >> "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch"
							wantitalbumartistdeezerid="$fuzzyaritstid"
							break
						fi					
					done
					if [ -z "$wantitalbumartistdeezerid" ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: No fuzzy match found..."
					fi
				else
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: \"${wantitalbumartistname}\"... musicbrainz id: ${wantitalbumartistmbid} is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
					echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/${wantitalbumartistmbid}/relationships for \"${wantitalbumartistname}\" with Deezer Artist Link" >> "musicbrainzerror.log"
					albumfuzzy=$(curl -s "https://api.deezer.com/search?q=artist:%22$sanatizedwantitalbumartistnamefuzzy%22%20album:%22$sanatizedwantitalbumtitlefuzzy%22")
					wantitalbumartistdeezeridfuzzy=($(echo "$albumfuzzy" | jq ".data | .[] | .artist.id" | sort -u))
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Attemtping fuzzy search for Artist: $wantitalbumartistname :: Album: $wantitalbumtitle"
					for id in "${!wantitalbumartistdeezeridfuzzy[@]}"; do
						currentprocess=$(( $id + 1 ))
						fuzzyaritstid=${wantitalbumartistdeezeridfuzzy[$id]}
						fuzzyaritstname="$(echo "$albumfuzzy" | jq ".data | .[] | .artist | select(.id==$fuzzyaritstid) | .name" | sort -u | sed -e "s/’/ /g" -e "s/'/ /g" -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
						if [ "$sanatizedwantitartistname" = "$fuzzyaritstname" ]; then
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: Match found!"
							touch "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch"
							echo "$fuzzyaritstid" >> "cache/$sanatizedartistname-${wantitalbumartisid}-fuzzymatch"
							wantitalbumartistdeezerid="$fuzzyaritstid"
							break
						fi					
					done
					if [ -z "$wantitalbumartistdeezerid" ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: No fuzzy match found..."			
					fi
				fi
			fi
		fi
		if [ "$wantitalbumartistname" != "Various Artists" ]; then
			if [ ! -z "$wantitalbumartistdeezerid" ]; then
				for deezerid in "${!wantitalbumartistdeezerid[@]}"; do
					deezeraritstid="${wantitalbumartistdeezerid[$deezerid]}"
					GetDeezerArtistAlbumList
				done
			fi
		else
			GetDeezerArtistAlbumList
		fi
	done
}

DeezerMatching () {
	fuzzyalbummatch="false"
	DeezerArtistMatchID=""
	if [ "$wantitalbumartistname" != "Various Artists" ]; then
		DeezerArtistAlbumListSortTotal=$(cat "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | .id" | wc -l)
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Checking.... $DeezerArtistAlbumListSortTotal Albums for match"		
		if [ -z "$DeezerArtistMatchID" ]; then
			# Check Album release records for match as backup because primary album title did not match
			for id in "${!wantitalbumrecordtitles[@]}"; do
				recordid=${wantitalbumrecordtitles[$id]}
				recordtitle="$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .title")"
				recordmbrainzid=$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .foreignReleaseId")
				recordtrackcount="$(echo "${wantitalbum}" | jq ".[] | .releases | .[] | select(.id==$recordid) | .trackCount")"
				sanatizedrecordtitle="$(echo "$recordtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Matching against: $recordtitle ($recordtrackcount Tracks)..."
				# Match using Sanatized Release Record Album Name + Track Count + Year
				if [ -z "$DeezerArtistMatchID" ]; then
					DeezerArtistMatchID=($(cat "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.actualtracktotal==$recordtrackcount) | select(.release_date | contains(\"$wantitalbumyear\")) | select(.sanatized_album_name==\"${sanatizedrecordtitle}\") | .id" | head -n1))
				fi
				
				# Match using Sanatized Album Name + Track Count
				if [ -z "$DeezerArtistMatchID" ]; then
					DeezerArtistMatchID=($(cat "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.actualtracktotal==$recordtrackcount) | select(.sanatized_album_name==\"${sanatizedrecordtitle}\") | .id" | head -n1))
				fi
				
				if [ ! -z "$DeezerArtistMatchID" ]; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Release Title: $recordtitle ($recordmbrainzid)"
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Track Count: $recordtrackcount"
					break
				fi
			done
		fi
	fi
	
	if [ -z "$DeezerArtistMatchID" ]; then
		if [ "$wantitalbumartistname" = "Various Artists" ]; then
			albumfuzzy=$(curl -s "https://api.deezer.com/search?q=album:%22$sanatizedwantitalbumtitlefuzzy%22")
			wantitalbumdeezeridfuzzy=($(echo "$albumfuzzy" | jq ".data | .[] | .album.id" | sort -u))
		# else
		#	albumfuzzy=$(curl -s "https://api.deezer.com/search?q=artist:%22$sanatizedwantitalbumartistnamefuzzy%22%20album:%22$sanatizedwantitalbumtitlefuzzy%22")
		#	wantitalbumdeezeridfuzzy=($(echo "$albumfuzzy" | jq ".data | .[] | .album.id" | sort -u))
		# fi
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Attemtping fuzzy search for Album: $wantitalbumtitle by: $wantitalbumartistname"
			for id in "${!wantitalbumdeezeridfuzzy[@]}"; do
				currentprocess=$(( $id + 1 ))
				fuzzyalbumid=${wantitalbumdeezeridfuzzy[$id]}
				albuminfo="$(curl -sL --fail "https://api.deezer.com/album/${fuzzyalbumid}")"
				fuzzyalbumname="$(echo "$albuminfo" | jq -r ".title" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
				fuzzyaritstname="$(echo "$albuminfo" | jq -r ".artist.name" | sort -u | sed -e "s/’/ /g" -e "s/'/ /g" -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/ /g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
				actualtracktotal=$(echo "$albuminfo" | jq -r ".tracks.data | .[] | .id" | wc -l)
				albumdate="$(echo "${albuminfo}" | jq -r ".release_date")"
				albumyear=$(echo ${albumdate:0:4})			
				fuzzymatcherror="false"				
				for id in "${!wantitalbumrecordtitles[@]}"; do
					recordid=${wantitalbumrecordtitles[$id]}
					recordtitle="$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .title")"
					recordmbrainzid=$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .foreignReleaseId")
					recordtrackcount="$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .trackCount")"
					sanatizedrecordtitle="$(echo "$recordtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"				
					fuzzymatcherror="false"
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Matching against: $recordtitle ($recordtrackcount Tracks)..."
					if [ "$fuzzymatcherror" != true ]; then
						if [ "$sanatizedwantitartistname" = "$fuzzyaritstname" ]; then
							fuzzymatcherror="false"
						else
							fuzzymatcherror="true"
						fi
					fi
					if [ "$fuzzymatcherror" != true ]; then
						if [ "$sanatizedwantitalbumtitle" = "$fuzzyalbumname" ]; then
							fuzzymatcherror="false"
						else
							fuzzymatcherror="true"
						fi
					fi
					if [ "$fuzzymatcherror" != true ]; then
						if [ "$wantitalbumtrackcount" = "$actualtracktotal" ]; then
							fuzzymatcherror="false"
						else
							fuzzymatcherror="true"
						fi
					fi
					if [ "$fuzzymatcherror" != true ]; then
						# Match using Sanatized Artist Name + Sanatized Album Name + Track Count + Year
						if [ "$wantitalbumyear" = "$albumyear" ]; then
							DeezerArtistMatchID="$fuzzyalbumid"
							fuzzyalbummatch="true"
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Release Title: $recordtitle ($recordmbrainzid)"
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Track Count: $recordtrackcount"
							break
						else
							DeezerArtistMatchID="$fuzzyalbumid"
							fuzzyalbummatch="true"
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Release Title: $recordtitle ($recordmbrainzid)"
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Track Count: $recordtrackcount"
							break
						fi
					fi
				done
			done
		fi
	fi

	if [ "$wantitalbumartistname" != "Various Artists" ]; then
		if [ -z "$DeezerArtistMatchID" ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: ERROR: Not found, fallback to fuzzy search..."
			if [ -z "$DeezerArtistMatchID" ]; then
				# Check Album release records for match as backup because primary album title did not match
				for id in "${!wantitalbumrecordtitles[@]}"; do
					recordid=${wantitalbumrecordtitles[$id]}
					recordtitle="$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .title")"
					recordmbrainzid=$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .foreignReleaseId")
					recordtrackcount="$(echo "${wantitalbum}" | jq -r ".[] | .releases | .[] | select(.id==$recordid) | .trackCount")"
					sanatizedrecordtitle="$(echo "$recordtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
					# Match using Sanatized Release Record Album Name + Track Count
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Matching against: $recordtitle ($recordtrackcount Tracks)..."
					if [ -z "$DeezerArtistMatchID" ]; then
						DeezerArtistMatchID=($(cat "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.actualtracktotal==$recordtrackcount) |  select(.sanatized_album_name | contains(\"${sanatizedrecordtitle}\")) | .id" | head -n1))
					fi

					if [ ! -z "$DeezerArtistMatchID" ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Release Title: $recordtitle ($recordmbrainzid)"
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Lidarr Matched Album Track Count: $recordtrackcount"
						break
					fi
				done
			fi

			if [ -z "$DeezerArtistMatchID" ]; then
				if ! [ -f "notfound.log" ]; then
					touch "notfound.log"
				fi
				if cat "notfound.log" | grep "${wantitalbummbid}" | read; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: ERROR: Not found, skipping... see: \"$(pwd)/notfound.log\" for more detail..."
				else
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: ERROR: Not found, skipping... see: \"$(pwd)/notfound.log\" for more detail..."
					echo "${wantitalbumartistname} :: $wantitalbumtitle (ID: ${wantitalbummbid}) :: Could not find a match on \"https://www.deezer.com/artist/${DeezerArtistID}\" using Release or Record Name, Track Count and Release Year, check artist page for album, ep or single. If exists, update musicbrainz db with matching album name, track count, year to resolve the error" >> "notfound.log"
					echo " "  >> "notfound.log"
				fi
			fi
		fi
	fi
}


GetDeezerArtistAlbumList () {
	if [ "$wantitalbumartistname" != "Various Artists" ]; then
		DeezerArtistID=$(echo "${deezeraritstid}" | grep -o '[[:digit:]]*')
		echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Artist ID: $DeezerArtistID"
		DLArtistArtwork
		DeezerMatching
	else
		DeezerMatching
	fi	
	
	if [ ! -z "$DeezerArtistMatchID" ]; then
		
		albumid="${DeezerArtistMatchID}"
		albumurl="https://www.deezer.com/album/${albumid}"
		if [ "$fuzzyalbummatch" = true ]; then
			albuminfo="$(curl -sL --fail "https://api.deezer.com/album/${albumid}")"
			actualtracktotal=$(echo "$albuminfo" | jq -r ".tracks.data | .[] | .id" | wc -l)
		else
			albuminfo="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json" | jq ".[] | select(.id==${albumid})")"
			actualtracktotal=$(echo "$albuminfo" | jq -r ".actualtracktotal")
		fi
		
		if [ -z "$albuminfo" ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ERROR: Cannot communicate with Deezer"
		else
					
			albumname=$(echo "${albuminfo}" | jq -r ".title")
			sanatizedalbumname="$(echo "${albumname}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			sanatizedartistname="$(echo "${wantitalbumartistname}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			tracktotal=$(echo "${albuminfo}" | jq -r ".nb_tracks")
			actualtracktotal=$(echo "$albuminfo" | jq -r ".actualtracktotal")
			albumdartistid=$(echo "${albuminfo}" | jq -r ".artist | .id")
			albumlyrictype="$(echo "${albuminfo}" | jq -r ".explicit_lyrics")"
			albumartworkurl="$(echo "${albuminfo}" | jq -r ".cover_xl")"
			albumdate="$(echo "${albuminfo}" | jq -r ".release_date")"
			albumyear=$(echo ${albumdate:0:4})
			albumtype="$(echo "${albuminfo}" | jq -r ".record_type")"
			albumtypecap="${albumtype^^}"
			albumduration=$(echo "${albuminfo}" | jq -r ".duration")
			albumdurationdisplay=$(DurationCalc $albumduration)
			importalbumfolder="${sanatizedartistname} - ${sanatizedalbumname} (${albumyear}) (${albumtypecap}) (WEB)-DLCLIENT"
			if [ "$albumlyrictype" = true ]; then
				albumlyrictype="Explicit"
			elif [ "$albumlyrictype" = false ]; then
				albumlyrictype="Clean"
			fi
			libalbumfolder="$sanatizedartistname - $albumtypecap - $albumyear - $albumid - $sanatizedalbumname ($albumlyrictype)"

			if ! [ -f "download.log" ]; then
				touch "download.log"
			fi
			
			if cat "download.log" | grep "${albumid}" | read; then
				downloaded="true"
			else
				downloaded="false"
			fi
			
			error=0

			if [ "${downloaded}" = false ] && [ $error = 0 ]; then		


				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Matched Album Title: $albumname (ID: $albumid)"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Link: $albumurl"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Release Year: $albumyear"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Release Type: $albumtype"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Lyric Type: $albumlyrictype"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Duration: $albumdurationdisplay"
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: Album Track Count: $tracktotal"

				CleanDLPath

				AlbumDL

				if [ $error = 1 ]; then
					CleanDLPath
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: ERROR: Download failed, skipping..."
				else

					DLAlbumArtwork
					
					downloadedtrackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
					downloadedlyriccount=$(find "$downloaddir" -type f -iname "*.lrc" | wc -l)
					downloadedalbumartcount=$(find "$downloaddir" -type f -iname "folder.*" | wc -l)
					replaygaintrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
					converttrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: $downloadedtrackcount Tracks"
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: $downloadedlyriccount Synced Lyrics"
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: $downloadedalbumartcount Album Cover"	

					TrackCountDownloadVerification

					if [ $error = 0 ]; then
						if [ "${RequireQuality}" = true ]; then
							QualityVerification
						fi
						
						beetsmatch="false"
						TagFix

						if [ "${TagWithBeets}" = true ]; then
							beetstagging
						fi				

						if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
						
							conversion "$downloaddir"

							if [ "${ReplaygainTagging}" = TRUE ]; then
								replaygain "$downloaddir"
							else
								echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: REPLAYGAIN TAGGING DISABLED"
							fi
							
							ImportFunction

							if [ "${DownLoadArtistArtwork}" = true ]; then
								DLArtistArtwork
							fi
						fi
						
					fi
				fi
			else
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DLCLIENT MATCH :: ERROR: Already downloaded, skipping... (see: download.log)" 
			fi
		fi
	fi
}

AlbumDL () {
	if cat "download.log" | grep "${albumid}" | read; then
		if [ $AudioMode = archive ]; then
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: Already Downloaded..."
		fi
		if [ $AudioMode = wanted ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: Already Downloaded..."
		fi
	else
		CleanDLPath
		if [ $AudioMode = archive ]; then
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: Sent to DL Client..."
		fi
		if [ $AudioMode = wanted ]; then
			echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: Sent to DL Client..."
		fi
		chmod 0777 -R "${PathToDLClient}"
		currentpwd="$(pwd)"
		if cd "${PathToDLClient}" && $python -m deemix -b ${dlquality} "$albumurl" &> /dev/null && cd "${currentpwd}"; then
			chmod 0777 -R "${downloaddir}"
			find "$downloaddir" -mindepth 2 -type f -exec mv "{}" "${downloaddir}"/ \;
			find "$downloaddir" -mindepth 1 -type d -delete
			if find "$downloaddir" -iname "*.flac" | read; then
				fallbackqualitytext="FLAC"
			elif find "$downloaddir" -iname "*.mp3" | read; then
				fallbackqualitytext="MP3"
			fi
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: Complete (Format: $fallbackqualitytext; Length: $albumdurationdisplay)"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: $albumname (Format: $fallbackqualitytext; Length: $albumdurationdisplay)"
			fi
			echo "Downloaded :: ${albumid} :: ${wantitalbumartistname} :: ${albumname} :: ${libalbumfolder}" >> "download.log"
			Verify
		else
			cd "${currentpwd}"
			error=1
		fi
	fi
}

Verify () {
	if find "$downloaddir" -iname "*.flac" | read; then
		if ! [ -x "$(command -v flac)" ]; then
			echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
		else
			for fname in "${downloaddir}"/*.flac; do
				filename="$(basename "$fname")"
				if flac -t --totally-silent "$fname"; then
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: VERIFYING :: Track: $filename Verified"
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: VERIFYING :: Track: $filename Verified"
					fi
				else
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: VERIFYING :: ERROR: Track $filename Verification failed, skipping album"
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: VERIFYING :: ERROR: Track $filename Verification failed, skipping album"
					fi
					rm -rf "$downloaddir"/*
					sleep 0.1
					error=1
				fi
			done
		fi
	fi
	if find "$downloaddir" -iname "*.mp3" | read; then
		if ! [ -x "$(command -v mp3val)" ]; then
			echo "MP3VAL verification utility not installed (ubuntu: apt-get install -y mp3val)"
		else
			for fname in "${downloaddir}"/*.mp3; do
				filename="$(basename "$fname")"
				if mp3val -f -nb "$fname" > /dev/null; then
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: VERIFYING :: Track: $filename Verified"
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: VERIFYING :: Track: $filename Verified"
					fi
				fi
			done
		fi
	fi
}

TagFix () {
	if find "$downloaddir" -iname "*.flac" | read; then
		if ! [ -x "$(command -v metaflac)" ]; then
			echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
		else
			for fname in "${downloaddir}"/*.flac; do
				filename="$(basename "$fname")"				
				if [ "$beetsmatch" = false ]; then
					metaflac "$fname" --remove-tag=ALBUMARTIST
					metaflac "$fname" --remove-tag=ALBUM
					metaflac "$fname" --set-tag=ALBUM="$albumname"
					metaflac "$fname" --set-tag=ALBUMARTIST="$wantitalbumartistname"
					metaflac "$fname" --set-tag=MUSICBRAINZ_ALBUMARTISTID=$lidarralbumartistmbrainzid
					if [ $DownloadMode = "wanted" ]; then
						metaflac "$fname" --set-tag=MUSICBRAINZ_RELEASEGROUPID=$wantitalbummbid
					fi
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: FIXING TAGS :: $filename fixed..."
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: FIXING TAGS :: $filename fixed..."
					fi
				else
					metaflac "$fname" --remove-tag=ALBUMARTIST
					metaflac "$fname" --set-tag=ALBUMARTIST="$wantitalbumartistname"
					metaflac "$fname" --remove-tag="ALBUM ARTIST"
					metaflac "$fname" --remove-tag=ALBUMARTISTSORT
					metaflac "$fname" --remove-tag=ARTISTSORT
					metaflac "$fname" --remove-tag=TRACK
					metaflac "$fname" --remove-tag=TRACKC
					metaflac "$fname" --remove-tag=R128_TRACK_GAIN
					metaflac "$fname" --remove-tag=R128_ALBUM_GAIN
					metaflac "$fname" --remove-tag=DISC
					metaflac "$fname" --remove-tag=DISCC
					metaflac "$fname" --remove-tag=COMPOSERSORT
					metaflac "$fname" --remove-tag=ARTIST_CREDIT
					metaflac "$fname" --remove-tag=ALBUMARTIST_CREDIT
					metaflac "$fname" --remove-tag=COMMENT
					metaflac "$fname" --remove-tag=ENCODEDBY
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: FIXING TAGS :: $filename fixed..."
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: FIXING TAGS :: $filename fixed..."
					fi
				fi
			done
		fi
	fi
	if find "$downloaddir" -iname "*.mp3" | read; then
		if ! [ -x "$(command -v eyeD3)" ]; then
			echo "eyed3 verification utility not installed (ubuntu: apt-get install -y eyed3)"
		else
			for fname in "${downloaddir}"/*.mp3; do
				filename="$(basename "$fname")"
				eyeD3 "$fname" -b "$wantitalbumartistname" &> /dev/null
				if [ "$beetsmatch" = false ]; then
					eyeD3 "$fname" -A "$albumname" &> /dev/null
					eyeD3 "$fname" --user-text-frame="MusicBrainz Album Artist Id:$lidarralbumartistmbrainzid" &> /dev/null
					if [ $DownloadMode = "wanted" ]; then
						eyeD3 "$fname" --user-text-frame="MusicBrainz Release Group Id:$wantitalbummbid" &> /dev/null
					fi
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: FIXING TAGS :: $filename fixed..."
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: FIXING TAGS :: $filename fixed..."
					fi
				else
					eyeD3 "$fname" --user-text-frame='ALBUMARTISTSORT:' &> /dev/null
					if [ $AudioMode = archive ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: FIXING TAGS :: $filename fixed..."
					fi
					if [ $AudioMode = wanted ]; then
						echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: FIXING TAGS :: $filename fixed..."
					fi
				fi
			done
		fi
	fi
}

conversion () {
	converttrackcount=$(find  "$1"/ -name "*.flac" | wc -l)
	targetformat="$quality"
	bitrate="$ConversionBitrate"
	if [ "${quality}" = "OPUS" ]; then	
		options="-acodec libopus -ab ${bitrate}k -application audio -vbr off"
		extension="opus"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = "AAC" ]; then
		options="-acodec aac -ab ${bitrate}k -movflags faststart"
		extension="m4a"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = "FDK-AAC" ]; then
		options="-acodec libfdk_aac -ab ${bitrate}k -movflags faststart"
		extension="m4a"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = "MP3" ]; then
		options="-acodec libmp3lame -ab ${bitrate}k"
		extension="mp3"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = "ALAC" ]; then
		options="-acodec alac -movflags faststart"
		extension="m4a"
		targetbitrate="lossless"
	fi
	if [ "${quality}" != "FLAC" ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "$1"/ -name "*.flac" | read; then
				if [ $AudioMode = archive ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: CONVERSION :: Converting: $converttrackcount Tracks (Target Format: $targetformat (${targetbitrate}))""
				fi
				if [ $AudioMode = wanted ]; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: :: CONVERSION :: Converting: $converttrackcount Tracks (Target Format: $targetformat (${targetbitrate}))""
				fi
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn $options "${fname%.flac}.temp.$extension"; then
						if [ $AudioMode = archive ]; then
							echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: CONVERSION :: $filename processed!"
						fi
						if [ $AudioMode = wanted ]; then
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: :: CONVERSION :: $filename processed!"
						fi
						if [ -f "${fname%.flac}.temp.$extension" ]; then
							rm "$fname"
							sleep 0.1
							mv "${fname%.flac}.temp.$extension" "${fname%.flac}.$extension"
						fi
					else
						if [ $AudioMode = archive ]; then
							echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: CONVERSION :: ERROR :: Coversion Failed: $filename, performing cleanup..."
						fi
						if [ $AudioMode = wanted ]; then
							echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: CONVERSION :: ERROR :: Coversion Failed: $filename, performing cleanup..."
						fi
						rm -rf "$1"/*
						sleep 0.1
					fi
				done
			fi
		else
			echo "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
			sleep 5
		fi
	fi
}

replaygain () {
	if ! [ -x "$(command -v flac)" ]; then
		echo "ERROR: METAFLAC replaygain utility not installed (ubuntu: apt-get install -y flac)"
	elif find "$1" -iname "*.flac" | read; then
		replaygaintrackcount=$(find  "$1"/ -iname "*.flac" | wc -l)
		if find "$1" -iname "*.flac" -exec metaflac --add-replay-gain "{}" +; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: REPLAYGAIN TAGGING :: $replaygaintrackcount tracks tagged!"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: REPLAYGAIN TAGGING :: $replaygaintrackcount tracks tagged!"
			fi
		fi
	fi
}

DLAlbumArtwork () {
	if [ ! -f "$downloaddir/folder.jpg" ]; then
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		file=$(find "$downloaddir" -iregex ".*/.*\.\(flac\|mp3\|opus\|m4a\)" | head -n 1)
		if [ ! -z "$file" ]; then
			artwork="$(dirname "$file")/folder.jpg"
			if ffmpeg -y -i "$file" -c:v copy "$downloaddir/folder.jpg" 2>/dev/null; then
				if [ $AudioMode = archive ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: Album Artwork..."
				fi
				if [ $AudioMode = wanted ]; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: Album Artwork..."
				fi
			else
				if [ $AudioMode = archive ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: ERROR: Album Artwork Download Failed..."
				fi
				if [ $AudioMode = wanted ]; then
					echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: DOWNLOAD :: ERROR: Album Artwork Download Failed..."
				fi
			fi
		fi
		IFS=$SAVEIFS
	fi
}

DLArtistArtwork () {
	if [ -d "$wantitalbumartispath" ]; then
		if [ ! -f "$wantitalbumartispath/folder.jpg"  ]; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: ARTIST ARTWORK :: Downloading..."
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ARTIST ARTWORK :: Downloading..."
			fi
			if curl -sL --fail "${LidarrUrl}/api/v1/MediaCover/Artist/${wantitalbumartisid}/poster.jpg?apikey=${LidarrApiKey}" -o "$wantitalbumartispath/folder.jpg"; then
				if [ -f "$wantitalbumartispath/folder.jpg"  ]; then	
					if find "$wantitalbumartispath/folder.jpg" -type f -size -16k | read; then
						rm "$wantitalbumartispath/folder.jpg"
					fi
				fi
			fi
		fi
		if [ "$wantitalbumartistname" != "Various Artists" ]; then
			if [ ! -z "${DeezerArtistID}" ]; then
				artistartwork=$(curl -s "https://api.deezer.com/artist/${DeezerArtistID}" | jq -r '.picture_xl')
				if [ ! -f "$wantitalbumartispath/folder.jpg"  ]; then
					if curl -sL --fail "${artistartwork}" -o "$wantitalbumartispath/folder.jpg"; then
						if [ -f "$wantitalbumartispath/folder.jpg"  ]; then	
							if find "$wantitalbumartispath/folder.jpg" -type f -size -16k | read; then
								rm "$wantitalbumartispath/folder.jpg"
							fi
						fi
					fi
				fi
			fi
		fi
		if [ -f "$wantitalbumartispath/folder.jpg"  ]; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: ARTIST ARTWORK :: Downloaded 1 profile picture"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ARTIST ARTWORK :: Downloaded 1 profile picture"
			fi
		else
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: ARTIST ARTWORK :: Error downloading artist artwork"
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: ARTIST ARTWORK :: Error downloading artist artwork"
			fi
		fi
	fi
}


TrackCountDownloadVerification () {
	if [ "$VerifyTrackCount" = true ]; then
		if [ "$tracktotal" -ne "$downloadedtrackcount" ]; then
			if [ $AudioMode = archive ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: TRACK COUNT DOWNLOAD VERIFCATION :: ERROR :: Downloaded Track Count ($downloadedtrackcount) and Album Track Count ($tracktotal) do not match, skipping and performing cleanup..."
			fi
			if [ $AudioMode = wanted ]; then
				echo "$currentprocess of $wantittotal :: $wantitalbumartistname :: $wantitalbumtitle :: TRACK COUNT DOWNLOAD VERIFCATION :: ERROR :: Downloaded Track Count ($downloadedtrackcount) and Album Track Count ($tracktotal) do not match, skipping and performing cleanup..."
			fi
			CleanDLPath
			error=1
		fi
	fi
}

ArtistMode () {
	echo "######################################### DOWNLOAD AUDIO (ARCHIVE MODE) #########################################"
	wantit=$(curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/Artist/")
	wantedtotal=$(echo "${wantit}"|jq -r '.[].sortName' | wc -l)

	MBArtistID=($(echo "${wantit}" | jq -r ".[$i].foreignArtistId"))

	for id in ${!MBArtistID[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${MBArtistID[$id]}"
		deezerartisturl=""

		LidArtistPath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		wantitalbumartispath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		LidArtistID="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .id")"
		wantitalbumartisid="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .id")"
		LidArtistNameCap="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		sanatizedartistname="$(echo "${LidArtistNameCap}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
		wantitalbumartistname="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		lidarrartistposterurl="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .images | .[] | select(.coverType==\"poster\") | .url")"
		lidarrartistposterextension="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .images | .[] | select(.coverType==\"poster\") | .extension")"
		lidarrartistposterlink="${LidarrUrl}${lidarrartistposterurl}${lidarrartistposterextension}"
		deezerartisturl=($(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .links | .[] | select(.name==\"deezer\") | .url"))
		
		if [ -z "${deezerartisturl}" ]; then	
			echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: ERROR: Fallback to musicbrainz for url..."
			mbjson=$(curl -s "${musicbrainzurl}/ws/2/artist/${mbid}?inc=url-rels&fmt=json")
			deezerartisturl=($(echo "$mbjson" | jq -r '.relations | .[] | .url | select(.resource | contains("deezer")) | .resource'))		
		fi	
		
		if [ -z "${deezerartisturl}" ]; then
			if ! [ -f "musicbrainzerror.log" ]; then
				touch "musicbrainzerror.log"
			fi		
			if [ -f "musicbrainzerror.log" ]; then
				echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: ERROR: musicbrainz id: $mbid is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
				if cat "musicbrainzerror.log" | grep "$mbid" | read; then
					sleep 0.1
				else
					echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/$mbid/relationships for \"${LidArtistNameCap}\" with Deezer Artist Link" >> "musicbrainzerror.log"
				fi
			fi
			continue
		fi

		for url in ${!deezerartisturl[@]}; do
			deezerid="${deezerartisturl[$url]}"
			DeezerArtistID=$(echo "${deezerid}" | grep -o '[[:digit:]]*')
			echo "#################### ARCHIVING ARTIST: $LidArtistNameCap ####################"
			if ! [ -f "cache/$sanatizedartistname-${DeezerArtistID}-info.json" ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: ERROR: Cannot communicate with Deezer"
				continue
			else
				ladarchive="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-info.json" | jq -r ".lad_archived")"
				if [ "$ladarchive" = "true" ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Already archived..."
					continue
				fi
			fi
			artistinfofile="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-info.json")"
			DeezerArtistName="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-info.json" | jq ".name" | sed -e 's/^"//' -e 's/"$//')"
			artistdir="$(basename "$LidArtistPath")"
			sanatizedlidarrartistname="$(echo "$LidArtistNameCap" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Lidarr Artist ID: $LidArtistID"
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Lidarr Artist Path: $LidArtistPath"
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Deezer Artist Name: $DeezerArtistName"
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Deezer Artist ID: $DeezerArtistID"
			echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: Deezer Artist URL: $deezerid"
					
			albumlistfile=$(cat "cache/$sanatizedartistname-$DeezerArtistID-albumlist.json")
			albumlist=($(echo "$albumlistfile" | jq -r "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | .id"))
			totalnumberalbumlist=($(echo "$albumlistfile"  | jq -r "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | .id" | wc -l))
			for album in ${!albumlist[@]}; do
				albumnumber=$(( $album + 1 ))
				albumid="${albumlist[$album]}"

				albumartistid=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .artist.id")
				if [ ! -f "cache/$sanatizedartistname-$albumartistid-info.json" ]; then
					continue
				fi
				albumurl="https://www.deezer.com/album/$albumid"
				albumname=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .title")
				albumartistname=$(echo "$albumlistfile"  | jq -r ".[]| select(.id=="$albumid") | .artist.name")
				albumtrackcount=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .nb_tracks")
				tracktotal=$(echo "$albumlistfile"  | jq -r ".[]| select(.id=="$albumid") | .nb_tracks")
				albumactualtrackcount=$(echo "$albumlistfile"  | jq -r ".[]| select(.id=="$albumid") | .actualtracktotal")
				albumexplicit=$(echo "$albumlistfile"  | jq -r ".[]| select(.id=="$albumid") | .explicit_lyrics")
				if [ $albumexplicit = true ]; then
					albumexplicit="Explicit"
				else
					albumexplicit="Clean"
				fi
				albumdate=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .release_date")
				albumyear=$(echo ${albumdate::4})
				albumtype=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .record_type")
				albumtypecaps="$(echo ${albumtype^^})"
				albumnamesanatized="$(echo "$albumname" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
				sanatizedfuncalbumname="${albumnamesanatized,,}"
				albumduration=$(echo "$albumlistfile" | jq -r ".[]| select(.id=="$albumid") | .duration")
				albumdurationdisplay=$(DurationCalc $albumduration)
				lidarralbumartistname="$(echo "$artistinfofile" | jq -r ".lidarr_artist_name")"
				wantitalbumartistname="$(echo "$artistinfofile" | jq -r ".lidarr_artist_name")"
				sanatizedalbumartistname="$(echo "$lidarralbumartistname" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
				lidarralbumartistfolder="$(echo "$artistinfofile" | jq -r ".lidarr_artist_path")"
				lidarralbumartistmbrainzid="$(echo "$artistinfofile" | jq -r ".mbrainzid")"
				libalbumfolder="$sanatizedalbumartistname - $albumtypecaps - $albumyear - $albumid - $albumnamesanatized ($albumexplicit)"
				importalbumfolder="${sanatizedalbumartistname} - ${albumnamesanatized} (${albumyear}) (${albumtypecaps}) (WEB)-DLCLIENT"
				echo "########## ARCHIVING TITLE: $albumname ##########"
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: $albumname :: $albumtypecaps :: $albumactualtrackcount Tracks :: $albumyear :: $albumexplicit :: $albumid"
				LidArtistPath="$lidarralbumartistfolder"

				if ! [ -f "download.log" ]; then
					touch "download.log"
				fi

				if cat "download.log" | grep -i ".* :: ${albumid} :: .*" | read; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate ($albumtypecaps), already downloaded... (see: download.log)"
					continue
				elif [ -d "${LidarrImportLocation}/${importalbumfolder}" ]; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate ($albumtypecaps), already downloaded but waiting for import..."
					ImportFunction
					continue
				elif [ "$albumtypecaps" = "ALBUM" ]; then
					if [ "$albumexplicit" = "Explicit" ]; then
						if cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized (Explicit)" | read; then
							echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
							continue
						elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized.*Deluxe.*(Explicit)" | read; then
							echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
							continue
						elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized (Clean)" | read; then
							echo "${artistnumber} of ${wantedtotal} :: $albumnumber of $totalnumberalbumlist :: Duplicate Clean ALBUM found, removing to import Explicit version..."
							find "$LidArtistPath" -type d -iname "*- ALBUM - * - * - $albumnamesanatized (Clean)" -exec rm -rf "{}" \;
							echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
						fi
					# Clean album processing, check for duplicate Explicit album
					elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized (Explicit)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
						continue
					# Clean album processing, check for duplicate Deluxe Explicit ALBUM
					elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized.*Deluxe.*(Explicit)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
						continue
					# Clean album processing, check for duplicate Deluxe Clean ALBUM
					elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized.*Deluxe.*(Clean)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
						continue
					# Clean album processing, check for duplicate clean album (same name)
					elif cat "download.log" | grep -i ".* - ALBUM - .* - $albumnamesanatized (Clean)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate (ALBUM), already downloaded..."
						continue
					else
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
					fi
				elif [ "$albumtypecaps" = "EP" ]; then

					if [ "$albumexplicit" = "Explicit" ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
					# Check for duplicate explicit EP
					elif cat "download.log" | grep -i ".* - EP - .* - $albumnamesanatized (Explicit)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate Explicit EP found, skipping..."
						continue
					# Check for duplicate clean EP
					elif cat "download.log" | grep -i ".* - EP - .* - $albumnamesanatized (Clean)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate Clean EP found, skipping..."
						continue
					else
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
					fi
				elif [ "$albumtypecaps" = "SINGLE" ]; then
					if [ "$albumexplicit" = "Explicit" ]; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
					# Check for duplicate explicit SINGLE
					elif cat "download.log" | grep -i ".* - SINGLE - .* - $albumnamesanatized (Explicit)" | read; then
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Duplicate Explicit SINGLE found, skipping..."
						continue
					else
						echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: Processing..."
					fi
				fi

				AlbumDL
				DLAlbumArtwork
				downloadedtrackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
				downloadedlyriccount=$(find "$downloaddir" -type f -iname "*.lrc" | wc -l)
				downloadedalbumartcount=$(find "$downloaddir" -type f -iname "folder.*" | wc -l)
				replaygaintrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
				converttrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
				TrackCountDownloadVerification
				
				if [ "${RequireQuality}" = true ]; then
					QualityVerification
				else
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: QUALITY VERIFICATION DISABLED"
				fi
						
				if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: $downloadedtrackcount Tracks"
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: $downloadedlyriccount Synced Lyrics"
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: DOWNLOAD :: $downloadedalbumartcount Album Cover"	
				else
					echo "Error..."
					continue
				fi
				
				beetsmatch="false"
				TagFix

				if [ "${TagWithBeets}" = true ]; then
					beetstagging
				else
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: BEETS TAGGING DISABLED"
				fi
				
				if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
					sleep 0.1
				else
					echo "Error..."
					continue
				fi
				conversion "$downloaddir"

				if [ "${ReplaygainTagging}" = TRUE ]; then
					replaygain "$downloaddir"
				else
					echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: $albumnumber of $totalnumberalbumlist :: REPLAYGAIN TAGGING DISABLED"
				fi
				
				ImportFunction
			done
			echo "#################### ARCHIVING ARTIST: $LidArtistNameCap COMPLETE ####################"
			if [ -f "cache/$sanatizedartistname-${DeezerArtistID}-info.json" ]; then
				echo "${artistnumber} of ${wantedtotal} :: ARCHIVING :: $LidArtistNameCap :: ARTIST CACHE :: Updating with successful archive information..."
				mv "cache/$sanatizedartistname-${DeezerArtistID}-info.json" "cache/${DeezerArtistID}-temp-info.json"
				jq ". + {\"lad_archived\": \"true\"}" "cache/${DeezerArtistID}-temp-info.json" > "cache/$sanatizedartistname-${DeezerArtistID}-info.json"
				rm "cache/${DeezerArtistID}-temp-info.json"
			fi
			if [ "${DownLoadArtistArtwork}" = true ] && [ -d "$LidArtistPath" ]; then
				DLArtistArtwork
			fi
		done
	done
}

DownloadVideos () {
	echo "######################################### DOWNLOADING VIDEOS #########################################"
	wantit=$(curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/Artist/")
	wantedtotal=$(echo "${wantit}"|jq -r '.[].sortName' | wc -l)
	MBArtistID=($(echo "${wantit}" | jq -r ".[$i].foreignArtistId"))

	for id in ${!MBArtistID[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${MBArtistID[$id]}"

		LidArtistPath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		LidArtistNameCap="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		sanatizedartistname="$(echo "${LidArtistNameCap}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"

		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Processing"

		if [ ! -d "video-cache" ]; then
			mkdir "video-cache"
			FolderAccessPermissions "video-cache"
		fi

		records=$(curl -s "${musicbrainzurl}/ws/2/recording?artist=$mbid&limit=1&offset=0&fmt=json")
		sleep $ratelimit
		newrecordingcount=$(echo "${records}"| jq -r '."recording-count"')

		recordingcount=$(cat "cache/$sanatizedartistname-$mbid-recording-count.json" | jq -r '."recording-count"')
		
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $recordingcount recordings found..."

		videorecordings=($(cat "cache/$sanatizedartistname-$mbid-recordings.json" | jq -r '.[] | .recordings | .[] | select(.video==true) | .id'))
		videocount=$(cat "cache/$sanatizedartistname-$mbid-recordings.json" | jq -r '.[] | .recordings | .[] | select(.video==true) | .id' | wc -l)
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Checking $recordingcount recordings for videos..."
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $videocount video recordings found..."

		if [ $videocount = 0 ]; then
			echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Skipping..."
			continue
		fi

		if [ ! -f "cache/$sanatizedartistname-$mbid-video-recordings.json" ]; then
			for id in ${!videorecordings[@]}; do
				currentprocess=$(( $id + 1 ))
				mbrainzrecordingid="${videorecordings[$id]}"
				echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $currentprocess of $videocount :: Gathering info..."
				if ! [ -d "temp" ]; then
					mkdir -p "temp"
				fi
				if [ ! -f "temp/$mbrainzrecordingid-recording-info.json" ]; then
					curl -s "${musicbrainzurl}/ws/2/recording/$mbrainzrecordingid?inc=url-rels&fmt=json" -o "temp/$mbrainzrecordingid-recording-info.json"
					sleep $ratelimit
				fi
			done

			if [ ! -f "cache/$sanatizedartistname-$mbid-video-recordings.json" ]; then
					jq -s '.' temp/*-recording-info.json > "cache/$sanatizedartistname-$mbid-video-recordings.json"
			fi

			if [ -f "cache/$sanatizedartistname-$mbid-video-recordings.json" ]; then
				rm temp/*-recording-info.json
			fi

			if [ -d "temp" ]; then
				rm -rf "temp"
			fi
		fi
		
		urlvideocount=$(cat "cache/$sanatizedartistname-$mbid-video-recordings.json" | jq -r '.[] | .relations | .[] | .url | .resource' | sort -u | wc -l)
		youtubeurl=($(cat "cache/$sanatizedartistname-$mbid-video-recordings.json" | jq -r '.[] | .relations | .[] | .url | .resource' | sort -u))
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Checking $videocount video recordings for links..."
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $urlvideocount links found!"
		if [ $urlvideocount = 0 ]; then
			echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Skipping..."
			continue
		fi
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Processing $urlvideocount links..."
		for url in ${!youtubeurl[@]}; do
			currentprocess=$(( $url + 1 ))
			dlurl="${youtubeurl[$url]}"
			videotitle="$(cat "cache/$sanatizedartistname-$mbid-video-recordings.json" | jq -r ".[] | select(.relations | .[] .url | .resource==\"$dlurl\") .title")"
			videodisambiguation="$(cat "cache/$sanatizedartistname-$mbid-video-recordings.json" | jq -r ".[] | select(.relations | .[] .url | .resource==\"$dlurl\") .disambiguation")"
			sanatizedvideotitle="$(echo "${videotitle}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			sanatizedvideodisambiguation="$(echo "${videodisambiguation}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			if [ ! -z "$videodisambiguation" ]; then
				sanatizedvideodisambiguation=" ($(echo "${videodisambiguation}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/'))"
			else
				sanatizedvideodisambiguation=""
			fi			
			if [ ! -f "$VideoPath/$sanatizedartistname - ${sanatizedvideotitle}${sanatizedvideodisambiguation}.mkv" ]; then 
				echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $currentprocess of $urlvideocount :: Downloading $videotitle ($dlurl)..."
				$python $YoutubeDL -o "$VideoPath/$sanatizedartistname - ${sanatizedvideotitle}${sanatizedvideodisambiguation}" -f bestvideo+bestaudio --merge-output-format mkv "$dlurl"  &> /dev/null
				if [ -f "$VideoPath/$sanatizedartistname - ${sanatizedvideotitle}${sanatizedvideodisambiguation}.mkv" ]; then 
					FileAccessPermissions "$LidArtistPath" &> /dev/null
					echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $currentprocess of $urlvideocount :: Download Complete!"
				else
					echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $currentprocess of $urlvideocount :: Downloaded Failed!"
				fi
			else
				echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $currentprocess of $urlvideocount :: $videotitle already downloaded!"
			fi
		done
		downloadcount=$(find "$VideoPath" -mindepth 1 -maxdepth 1 -type f -iname "$sanatizedartistname - *" | wc -l)
		echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: $downloadcount Vidoes Downloaded!"
	done
	totaldownloadcount=$(find "$VideoPath" -mindepth 1 -maxdepth 1 -type f -iname "*.mkv" | wc -l)
	echo "######################################### $totaldownloadcount VIDEOS DOWNLOADED #########################################"
}

CacheEngine () {
	echo "######################################### STARTING CACHE ENGINE #########################################"
	if [ ! -d "cache" ]; then
		mkdir "cache"
		FolderAccessPermissions "cache"
	fi

	wantit=$(curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/Artist/")
	wantedtotal=$(echo "${wantit}"|jq -r '.[].sortName' | wc -l)
	MBArtistID=($(echo "${wantit}" | jq -r ".[$i].foreignArtistId"))

	for id in ${!MBArtistID[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${MBArtistID[$id]}"
		deezerartisturl=""

		LidArtistPath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		wantitalbumartispath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		LidArtistID="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .id")"
		wantitalbumartisid="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .id")"
		LidArtistNameCap="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		sanatizedartistname="$(echo "${LidArtistNameCap}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
		wantitalbumartistname="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		lidarrartistposterurl="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .images | .[] | select(.coverType==\"poster\") | .url")"
		lidarrartistposterextension="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .images | .[] | select(.coverType==\"poster\") | .extension")"
		lidarrartistposterlink="${LidarrUrl}${lidarrartistposterurl}${lidarrartistposterextension}"
		deezerartisturl=($(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .links | .[] | select(.name==\"deezer\") | .url"))

		if [ $DownloadMode = "Both" ] || [ $DownloadMode = "Audio" ]; then

			if [ -z "${deezerartisturl}" ]; then	
				echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: ERROR: Fallback to musicbrainz for url..."
				mbjson=$(curl -s "${musicbrainzurl}/ws/2/artist/${mbid}?inc=url-rels&fmt=json")
				deezerartisturl=($(echo "$mbjson" | jq -r '.relations | .[] | .url | select(.resource | contains("deezer")) | .resource'))		
			fi	
			
			if [ -z "${deezerartisturl}" ]; then
				if ! [ -f "musicbrainzerror.log" ]; then
					touch "musicbrainzerror.log"
				fi		
				if [ -f "musicbrainzerror.log" ]; then
					echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: ERROR: musicbrainz id: $mbid is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
					if cat "musicbrainzerror.log" | grep "$mbid" | read; then
						sleep 0.1
					else
						echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/$mbid/relationships for \"${LidArtistNameCap}\" with Deezer Artist Link" >> "musicbrainzerror.log"
					fi
				fi
				continue
			fi

			if ! [ -d "cache" ]; then
				mkdir -p "cache"
			fi

			if ! [ -d "temp" ]; then
				mkdir -p "temp"
			fi

			for url in ${!deezerartisturl[@]}; do
				deezerid="${deezerartisturl[$url]}"
				DeezerArtistID=$(echo "${deezerid}" | grep -o '[[:digit:]]*')
				if  [ -f "cache/$sanatizedartistname-${DeezerArtistID}-info.json" ]; then
					check="fail"
					lidarralbumartistname="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-info.json" | jq -r ".lidarr_artist_name")"
					lidarralbumartistmbrainzid="$(cat "cache/$sanatizedartistname-${DeezerArtistID}-info.json" | jq -r ".mbrainzid")"
					if [ "$lidarralbumartistname" != null ]; then
						check="success"
					else
						check="fail"
						rm "cache/$sanatizedartistname-$sanatizedartistname-${DeezerArtistID}-info.json"
						echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Cached Arist Info invalid, cleaning up before caching..."
					fi
					if [ "$lidarralbumartistmbrainzid" != null ]; then
						check="success"
					else
						check="fail"
						rm "cache/$sanatizedartistname-${DeezerArtistID}-info.json"
						echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Cached Arist Info invalid, cleaning up before caching..."
					fi
					if [ $check = success ]; then
						echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Cached Artist Info verified..."
					fi
				elif ! [ -f "cache/$sanatizedartistname-${DeezerArtistID}-info.json" ]; then
					if curl -sL --fail "https://api.deezer.com/artist/${DeezerArtistID}" -o "temp/${DeezerArtistID}-temp-info.json"; then
						jq ". + {\"lidarr_artist_path\": \"$LidArtistPath\"} + {\"lidarr_artist_name\": \"$LidArtistNameCap\"} + {\"mbrainzid\": \"$mbid\"}" "temp/${DeezerArtistID}-temp-info.json" > "cache/$sanatizedartistname-${DeezerArtistID}-info.json"
						echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Caching Artist Info..."
						rm "temp/${DeezerArtistID}-temp-info.json"
					else
						echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: ERROR: Cannot communicate with Deezer"
						continue
					fi
				fi

				if [ "$LidArtistNameCap" != "Various Artists" ]; then				
					if [ ! -f "cache/$sanatizedartistname-$DeezerArtistID-checked" ]; then
						if [ ! -f "cache/$sanatizedartistname-$DeezerArtistID-album.json" ]; then
							DeezerArtistAlbumList=$(curl -s "https://api.deezer.com/artist/${DeezerArtistID}/albums&limit=1000")
							if [ -z "$DeezerArtistAlbumList" ]; then
								echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: ERROR: Unable to retrieve albums from Deezer"										
							fi
						fi				
					else
						DeezerArtistAlbumList=$(curl -s "https://api.deezer.com/artist/${DeezerArtistID}/albums&limit=1000")
						newalbumlist="$(echo "${DeezerArtistAlbumList}" | jq ".data | .[] | .id" | wc -l)"
						if [ -z "$DeezerArtistAlbumList" ] || [ -z "${newalbumlist}" ]; then
							echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: ERROR: Unable to retrieve albums from Deezer"										
						fi
					fi
				else
					continue
				fi	

				# Check cache deezer artistid album list for matching discography album count, if different, delete
				if [ ! -f "cache/$sanatizedartistname-$DeezerArtistID-checked" ]; then
					if [ -f "cache/$sanatizedartistname-$DeezerArtistID-albumlist.json" ]; then
						cachealbumlist="$(cat "cache/$sanatizedartistname-$DeezerArtistID-albumlist.json" | jq '.[].id' | wc -l)"
						if [ "${newalbumlist}" -ne "${cachealbumlist}" ]; then
							echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Existing Cached Deezer Artist Album list is out of date, updating..."
							rm "cache/$sanatizedartistname-${DeezerArtistID}-albumlist.json"
							sleep 0.1
						else
							echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Exisiting Cached Deezer Artist (ID: ${DeezerArtistID}) Album List is current..."
							touch "cache/$DeezerArtistID-checked"
						fi
					fi
				else
					echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Exisiting Cached Deezer Artist (ID: ${DeezerArtistID}) Album List is current..."
				fi
				
				# Cahche deezer artistid album list and save to file for re-use...
				if [ ! -f "cache/$sanatizedartistname-$DeezerArtistID-albumlist.json" ]; then
					echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Caching Deezer Artist (ID: ${DeezerArtistID}) Album List..."
					
					if [ -d "temp" ]; then
						sleep 0.1
						rm -rf "temp"
					fi
					
					DeezerArtistAlbumListID=($(echo "${DeezerArtistAlbumList}" | jq ".data | .[] | .id"))
					DeezerArtistName=($(echo "${DeezerArtistAlbumList}" | jq ".data | .[] | .id"))
					for id in ${!DeezerArtistAlbumListID[@]}; do
						albumid="${DeezerArtistAlbumListID[$id]}"
						if [ ! -d "temp" ]; then
							mkdir -p "temp" 
						fi
						if curl -sL --fail "https://api.deezer.com/album/${albumid}" -o "temp/${albumid}-temp-album.json"; then
							sleep 0.5
							albumtitle="$(cat "temp/${albumid}-temp-album.json" | jq ".title")"
							actualtracktotal=$(cat "temp/${albumid}-temp-album.json" | jq -r ".tracks.data | .[] | .id" | wc -l)
							sanatizedalbumtitle="$(echo "$albumtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
							jq ". + {\"sanatized_album_name\": \"$sanatizedalbumtitle\"} + {\"actualtracktotal\": $actualtracktotal}" "temp/${albumid}-temp-album.json" > "temp/${albumid}-album.json"
							rm "temp/${albumid}-temp-album.json"
							sleep 0.1
						else
							echo "${artistnumber} of ${wantedtotal} :: $LidArtistNameCap :: Audio Cache :: Error getting album information"
						fi				
					done
					
					# Cleanup temp files...
					if [ -f "downloadlist.json" ]; then
						rm "downloadlist.json"
						sleep 0.1
					fi
									
					if [ ! -d "cache" ]; then
						sleep 0.1
						mkdir -p "cache"
					fi
					
					jq -s '.' temp/*-album.json > "cache/$sanatizedartistname-$DeezerArtistID-albumlist.json"
					touch "cache/$sanatizedartistname-$DeezerArtistID-checked"
					
					if [ -d "temp" ]; then
						sleep 0.1
						rm -rf "temp"
					fi	
				fi
			done
			if [ -d "temp" ]; then
				rm -rf "temp"
			fi
		fi 

		if [ $DownloadMode = "Both" ] || [ $DownloadMode = "Video" ]; then

			records=$(curl -s "${musicbrainzurl}/ws/2/recording?artist=$mbid&limit=1&offset=0&fmt=json")
			sleep $ratelimit
			newrecordingcount=$(echo "${records}"| jq -r '."recording-count"')
				
			if [ ! -f "cache/$sanatizedartistname-$mbid-recording-count.json" ]; then
				curl -s "${musicbrainzurl}/ws/2/recording?artist=$mbid&limit=1&offset=0&fmt=json" -o "cache/$sanatizedartistname-$mbid-recording-count.json"
				sleep $ratelimit
			fi

			recordingcount=$(cat "cache/$sanatizedartistname-$mbid-recording-count.json" | jq -r '."recording-count"')
			
			if [ $newrecordingcount != $recordingcount ]; then
				echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Video Cache :: Cache needs update, cleaning..."
				if [ -f "cache/$sanatizedartistname-$mbid-recordings.json" ]; then
					rm "cache/$sanatizedartistname-$mbid-recordings.json"
				fi
				if [ -f "cache/$sanatizedartistname-$mbid-recording-count.json" ]; then
					rm "cache/$sanatizedartistname-$mbid-recording-count.json"
				fi
				if [ -f "cache/$sanatizedartistname-$mbid-video-recordings.json" ]; then
					rm "cache/$sanatizedartistname-$mbid-video-recordings.json"
				fi
				if [ ! -f "cache/$sanatizedartistname-$mbid-recording-count.json" ]; then
					curl -s "${musicbrainzurl}/ws/2/recording?artist=$mbid&limit=1&offset=0&fmt=json" -o "cache/$sanatizedartistname-$mbid-recording-count.json"
					sleep $ratelimit
				fi
			else
				if [ ! -f "cache/$sanatizedartistname-$mbid-recordings.json" ]; then
					echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Video Cache :: Caching $recordingcount Recordings..."
				else
					echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Video Cache :: Video Cache Is Valid..."
				fi
			fi

			if [ ! -f "cache/$sanatizedartistname-$mbid-recordings.json" ]; then
				if [ ! -d "temp" ]; then
					mkdir "temp"
					sleep 0.1
				fi	
				offsetcount=$(( $recordingcount / 100 ))
				for ((i=0;i<=$offsetcount;i++)); 
				do
					if [ ! -f "recording-page-$i.json" ]; then
						if [ $i != 0 ]; then
							offset=$(( $i * 100 ))
							dlnumber=$(( $offset + 100))
						else
							offset=0
							dlnumber=$(( $offset + 100))
						fi
						echo "$artistnumber of $wantedtotal :: $LidArtistNameCap :: Video Cache :: Downloading page $i... ($offset - $dlnumber Results)"
						curl -s "${musicbrainzurl}/ws/2/recording?artist=$mbid&limit=100&offset=$offset&fmt=json" -o "temp/$mbid-recording-page-$i.json"
						sleep $ratelimit
					fi
				done


				if [ ! -f "cache/$sanatizedartistname-recordings.json" ]; then
					jq -s '.' temp/$mbid-recording-page-*.json > "cache/$sanatizedartistname-$mbid-recordings.json"
				fi

				if [ -f "cache/$sanatizedartistname-$mbid-recordings.json" ]; then
					rm temp/$mbid-recording-page-*.json
					sleep .01
				fi

				if [ -d "temp" ]; then
					sleep 0.1
					rm -rf "temp"
				fi
			fi
		fi

	done
	echo "######################################### $wantedtotal ARTISTS CACHED #########################################"

}

paths

configuration

CleanDLPath

if ! [ $ImportMode = manual ]; then
	CleanImportPath
fi

CleanCacheCheck

CleanNotfoundLog

CleanMusicbrainzLog

CacheEngine

if [ $DownloadMode = "Both" ] || [ $DownloadMode = "Audio" ]; then
	if [ $AudioMode = "wanted" ]; then
		LidarrAlbums
		ProcessLidarrAlbums
	elif [ $AudioMode = "archive" ]; then
		ArtistMode
	fi
fi

if [ $DownloadMode = "Both" ] || [ $DownloadMode = "Video" ]; then
	DownloadVideos
fi

CleanDLPath

CleanCacheCheck

#####################################################################################################
#                                              Script End                                           #
#####################################################################################################
exit 0
