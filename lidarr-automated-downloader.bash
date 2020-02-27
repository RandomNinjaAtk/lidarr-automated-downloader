#!/bin/bash
#####################################################################################################
#                                     Lidarr Automated Downloader                                   #
#                                       Credit: RandomNinjaAtk                                      #
#####################################################################################################
#                                           Script Start                                            #
#####################################################################################################

############ Import Script Settings
source ./config

configuration () {
	
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
	
	echo ""
	echo "Global Settings"
	echo "Download Client: $deezloaderurl"
	echo "Download Directory: $downloaddir"
	echo "Lidarr Temp Import Location: $LidarrImportLocation"
	echo "Download Quality: $quality"
	if [ "$quality" = "OPUS" ]; then
		echo "Download Bitrate: ${ConversionBitrate}k"
	elif [ "$quality" = "AAC" ]; then
		echo "Download Bitrate: ${ConversionBitrate}k"
	elif [ "$quality" = "MP3" ]; then
		echo "Download Bitrate: ${ConversionBitrate}k"
	else
		echo "Download Bitrate: lossless"
	fi
	echo "Download Track Count Verification: $vtc"
	if [ "$quality" = "FLAC" ]; then
		echo "Replaygain Tagging: $gain"
	fi
	echo "Total Number of Albums To Process: $wantittotal"
	echo ""
	echo "Begin finding downloads..."
	echo ""
	sleep 1.5
	
	if [ "$quality" != "MP3" ]; then
		dlquality="flac"
	else
		dlquality="mp3"
	fi
}

paths () {

	if [ ! -d "$downloaddir" ]; then
		mkdir -p "$downloaddir"
	fi
	
	if [ ! -d "$LidarrImportLocation" ]; then
		mkdir -p "$LidarrImportLocation"
	fi
	
}

CleanDLPath () {
	echo "Cleaning Download directory..."
	rm -rf "$downloaddir"/*
}

CleanImportPath () {
	echo "Cleaning Lidarr Import directory..."
	if [ -f "${LidarrImportLocation}/cleanup" ]; then
		rm "${LidarrImportLocation}/cleanup"
	fi
	touch -d "3 hours ago" "${LidarrImportLocation}/cleanup"
	find "${LidarrImportLocation}" -type d -not -newer "${LidarrImportLocation}/cleanup" -exec rm -rf "{}" \; > /dev/null 2>&1
	rm "${LidarrImportLocation}/cleanup"
}

FileAccessPermissions () {
	echo "Setting file permissions (${FilePermissions})"
	chmod ${FilePermissions} "$1"/*
}

FolderAccessPermissions () {
	echo "Setting folder permissions (${FolderPermissions})"
	chmod ${FolderPermissions} "$1"
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

LidarrAlbums () {

	
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

	echo "Getting Lidarr missing and cutoff albums list for processing..."

	curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/wanted/missing/?page=1&pagesize=${amount}&includeArtist=true&monitored=true&sortDir=desc&sortKey=releaseDate" -o temp-lidarr-missing.json
	curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/wanted/cutoff/?page=1&pagesize=${amount}&includeArtist=true&monitored=true&sortDir=desc&sortKey=releaseDate" -o temp-lidarr-cutoff.json
	missingtotal=$(cat "temp-lidarr-missing.json"| jq -r '.records | .[] | .id' | wc -l)
	cuttofftotal=$(cat "temp-lidarr-cutoff.json"| jq -r '.records | .[] | .id' | wc -l)
	jq -s '.[]' temp-lidarr-*.json > "lidarr-monitored-list.json"
	wantit=$(cat "lidarr-monitored-list.json")
	wantitid=($(echo "${wantit}"| jq -r '.records | .[] | .id'))
	wantittotal=$(echo "${wantit}"| jq -r '.records | .[] | .id' | wc -l)
	echo "${missingtotal} Missing Albums Found"
	echo "${cuttofftotal} Cutoff Albums Found"

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
		wantitalbumtitle=$(echo "${wantitalbum}"| jq -r '.[] | .title')
		wantitalbumyear="$(echo "${wantitalbum}"| jq -r '.[] | .releaseDate')"
		wantitalbumyear="${wantitalbumyear:0:4}"
		wantitalbumtrackcount=$(echo "${wantitalbum}"| jq -r '.[] | .statistics.trackCount')
		wantitalbumalbumType=$(echo "${wantitalbum}"| jq -r '.[] | .albumType')
		wantitalbumartistname=$(echo "${wantitalbum}"| jq -r '.[] | .artist.artistName')
		wantitalbumartistmbid=$(echo "${wantitalbum}"| jq -r '.[] | .artist.foreignArtistId')
		wantitalbumartistdeezerid=($(echo "${wantitalbum}"| jq -r '.[] | .artist.links | .[] |  select(.name=="deezer") | .url'))
		normalizetype="${wantitalbumalbumType,,}"
		sanatizedwantitalbumtitle="$(echo "$wantitalbumtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
		echo "Lidarr Artist Name: $wantitalbumartistname (ID: ${wantitalbumartistmbid})"
		echo "Lidarr Album Title: $wantitalbumtitle ($currentprocess of $wantittotal)"
		echo "Lidarr Album Year: $wantitalbumyear"
		echo "Lidarr Album Type: $normalizetype" 
		echo "Lidarr Album Track Count: $wantitalbumtrackcount"
				
		if [ -z "${wantitalbumartistdeezerid}" ]; then	
			echo "ERROR: Fallback to musicbrainz for url..."
			mbjson=$(curl -s "http://musicbrainz.org/ws/2/artist/${wantitalbumartistmbid}?inc=url-rels&fmt=json")
			wantitalbumartistdeezerid=($(echo "$mbjson" | jq -r '.relations | .[] | .url | select(.resource | contains("deezer")) | .resource'))		
		fi	

		if [ -z "$wantitalbumartistdeezerid" ]; then
			if ! [ -f "musicbrainzerror.log" ]; then
				touch "musicbrainzerror.log"
			fi
			if cat "musicbrainzerror.log" | grep "${wantitalbumartistmbid}" | read; then
				echo "ERROR: \"${wantitalbumartistname}\"... musicbrainz id: ${wantitalbumartistmbid} is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
			else
				echo "ERROR: \"${wantitalbumartistname}\"... musicbrainz id: ${wantitalbumartistmbid} is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
				echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/${wantitalbumartistmbid}/relationships for \"${wantitalbumartistname}\" with Deezer Artist Link" >> "musicbrainzerror.log"
				echo ""
				continue
			fi
		fi
		
		if [ ! -z "$wantitalbumartistdeezerid" ]; then
			for deezerid in "${!wantitalbumartistdeezerid[@]}"; do
				deezeraritstid="${wantitalbumartistdeezerid[$deezerid]}"
				GetDeezerArtistAlbumList
			done
		fi
	
	done
}

DeezerMatching () {

	DeezerArtistMatchID=""
	DeezerArtistAlbumListSortTotal=$(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | .id" | wc -l)
	echo "Checking.... $DeezerArtistAlbumListSortTotal Albums for match"
	
	if [ -z "$DeezerArtistMatchID" ]; then
		DeezerArtistMatchID=($(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.nb_tracks==$wantitalbumtrackcount) | select(.release_date | contains(\"$wantitalbumyear\")) | select(.sanatized_album_name==\"${sanatizedwantitalbumtitle}\") | .id" | head -n1))
	fi

	if [ -z "$DeezerArtistMatchID" ]; then
		DeezerArtistMatchID=($(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.nb_tracks==$wantitalbumtrackcount) | select(.sanatized_album_name==\"${sanatizedwantitalbumtitle}\") | .id" | head -n1))
	fi

	if [ -z "$DeezerArtistMatchID" ]; then
		# Check Album release records for match as backup because primary album title did not match
		for id in "${!wantitalbumrecordtitles[@]}"; do
			recordid=${wantitalbumrecordtitles[$id]}
			recordtitle="$(echo "${wantitalbum}" | jq ".[] | .releases | .[] | select(.id==$recordid) | .title")"
			recordtrackcount="$(echo "${wantitalbum}" | jq ".[] | .releases | .[] | select(.id==$recordid) | .trackCount")"
			sanatizedrecordtitle="$(echo "$recordtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
			
			if [ -z "$DeezerArtistMatchID" ]; then
				DeezerArtistMatchID=($(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.nb_tracks==$recordtrackcount) | select(.release_date | contains(\"$wantitalbumyear\")) | select(.sanatized_album_name==\"${sanatizedrecordtitle}\") | .id" | head -n1))
			fi

			if [ -z "$DeezerArtistMatchID" ]; then
				DeezerArtistMatchID=($(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.nb_tracks==$recordtrackcount) | select(.sanatized_album_name==\"${sanatizedrecordtitle}\") | .id" | head -n1))
			fi
			
			if [ ! -z "$DeezerArtistMatchID" ]; then
				echo "Lidarr Matched Album Release Title: $recordtitle"
				echo "Lidarr Matched Album Track Count: $recordtrackcount"
				break
			fi
		done
	fi
	
	if [ -z "$DeezerArtistMatchID" ]; then
		echo "ERROR: Not found, fallback to fuzzy search"
		if [ -z "$DeezerArtistMatchID" ]; then
			DeezerArtistMatchID=($(cat "cache/${DeezerArtistID}-albumlist.json" | jq "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | select(.nb_tracks==$wantitalbumtrackcount) | select(.release_date | contains(\"$wantitalbumyear\")) | select(.sanatized_album_name | contains(\"${sanatizedwantitalbumtitle}\")) | .id" | head -n1))
		fi
		if [ -z "$DeezerArtistMatchID" ]; then
			echo "ERROR: Not found, skipping..."
		fi
	fi
}

DownloadList () {
	
	if [ -f "cache/$DeezerArtistID-albumlist.json" ]; then
		cachealbumlist="$(cat "cache/$DeezerArtistID-albumlist.json" | jq '.[].id' | wc -l)"
		if [ "${newalbumlist}" -ne "${cachealbumlist}" ]; then
			echo "Existing Cached Deezer Artist Album list is out of date, updating..."
			rm "cache/$DeezerArtistID-albumlist.json"
			sleep 0.1
		else
			echo "Exisiting Cached Deezer Artist (ID: ${DeezerArtistID}) Album List is current..."
		fi
	fi	

	if [ ! -f "cache/$DeezerArtistID-albumlist.json" ]; then
		
		echo "Caching Deezer Artist (ID: ${DeezerArtistID}) Album List for matching..."
		
		if [ -d "temp" ]; then
			sleep 0.1
			rm -rf "temp"
		fi
		DeezerArtistAlbumListID=($(echo "${DeezerArtistAlbumList}" | jq ".data | .[] | .id"))
		for id in ${!DeezerArtistAlbumListID[@]}; do
			albumid="${DeezerArtistAlbumListID[$id]}"
			if [ ! -d "temp" ]; then
				mkdir -p "temp" 
			fi
			if curl -sL --fail "https://api.deezer.com/album/${albumid}" -o "temp/${albumid}-temp-album.json"; then
				sleep 0.1
				albumtitle="$(cat "temp/${albumid}-temp-album.json" | jq ".title")"
				sanatizedalbumtitle="$(echo "$albumtitle" | sed -e 's/[^[:alnum:]\ ]//g' -e 's/[[:space:]]\+/-/g' -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/./\L&/g')"
				jq ". + {\"sanatized_album_name\": \"$sanatizedalbumtitle\"}" "temp/${albumid}-temp-album.json" > "temp/${albumid}-album.json"
				rm "temp/${albumid}-temp-album.json"
				sleep 0.1
			else
				echo "Error getting album information"
			fi				
		done
		
		if [ -f "downloadlist.json" ]; then
			rm "downloadlist.json"
			sleep 0.1
		fi
						
		if [ ! -d "cache" ]; then
			sleep 0.1
			mkdir -p "cache"
		fi
		
		jq -s '.' temp/*-album.json > "cache/$DeezerArtistID-albumlist.json"
		
		if [ -d "temp" ]; then
			sleep 0.1
			rm -rf "temp"
		fi
		
	fi
}

GetDeezerArtistAlbumList () {

	DeezerArtistID=$(echo "${deezeraritstid}" | grep -o '[[:digit:]]*')
	echo "Deezer Artist ID: $DeezerArtistID"
	DeezerArtistAlbumList=$(curl -s "https://api.deezer.com/artist/${DeezerArtistID}/albums&limit=1000")
	newalbumlist="$(echo "${DeezerArtistAlbumList}" | jq ".data | .[] | .id" | wc -l)"
	if [ -z "$DeezerArtistAlbumList" ] || [ -z "${newalbumlist}" ]; then
		echo "ERROR: Unable to retrieve albums from Deezer"
	else
	
		DownloadList
		
		DeezerMatching
		
	fi	
	
	if [ ! -z "$DeezerArtistMatchID" ]; then
		albumid="${DeezerArtistMatchID}"
		albumurl="https://www.deezer.com/album/${albumid}"
		albuminfo=$(curl -sL --fail "https://api.deezer.com/album/$albumid")
		
		if [ -z "$albuminfo" ]; then
			echo "ERROR: Cannot communicate with Deezer"
		else
					
			albumname=$(echo "${albuminfo}" | jq -r ".title")
			sanatizedalbumname="$(echo "${albumname}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			sanatizedartistname="$(echo "${wantitalbumartistname}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			tracktotal=$(echo "${albuminfo}" | jq -r ".nb_tracks")
			actualtracktotal=$(echo "$albuminfo" | jq -r ".tracks.data | .[] | .id" | wc -l)
			albumdartistid=$(echo "${albuminfo}" | jq -r ".artist | .id")
			albumlyrictype="$(echo "${albuminfo}" | jq -r ".explicit_lyrics")"
			albumartworkurl="$(echo "${albuminfo}" | jq -r ".cover_xl")"
			albumdate="$(echo "${albuminfo}" | jq -r ".release_date")"
			albumyear=$(echo ${albumdate::4})
			albumtype="$(echo "${albuminfo}" | jq -r ".record_type")"
			albumtypecap="${albumtype^^}"
			albumduration=$(echo "${albuminfo}" | jq -r ".duration")
			albumdurationdisplay=$(DurationCalc $albumduration)
			albumtimeout=$(($albumduration*$albumtimeoutpercentage/100))
			albumtimeoutdisplay=$(DurationCalc $albumtimeout)
			albumfallbacktimout=$(($albumduration*2))
			importalbumfolder="${sanatizedartistname} - ${sanatizedalbumname} (${albumyear}) (${albumtypecap}) (WEB)-DREMIX"

			if ! [ -f "download.log" ]; then
				touch "download.log"
			fi
			
			if cat "download.log" | grep "${albumid}" | read; then
				downloaded="true"
			else
				downloaded="false"
			fi
			
			error=0

			TrackCountVerification
			
			if [ ! -d "$LidarrImportLocation/$importalbumfolder" ] && [ "${downloaded}" = false ] && [ $error = 0 ]; then		

				if [ "$albumlyrictype" = true ]; then
					albumlyrictype="Explicit"
				elif [ "$albumlyrictype" = false ]; then
					albumlyrictype="Clean"
				fi

				echo "Deezer Matched Album Title: $albumname (ID: $albumid)"
				echo "Album Link: $albumurl"
				echo "Album Release Year: $albumyear"
				echo "Album Release Type: $albumtype"
				echo "Album Lyric Type: $albumlyrictype"
				echo "Album Duration: $albumdurationdisplay"
				echo "Album Track Count: $tracktotal"

				CleanDLPath

				AlbumDL

				if [ $trackdlfallback = 1 ]; then
					CleanDLPath
					TrackMethod
				fi

				if [ $error = 1 ]; then
					CleanDLPath
					echo "ERROR: Download failed, skipping..."
				else

					DLAlbumArtwork

					downloadedtrackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
					downloadedlyriccount=$(find "$downloaddir" -type f -iname "*.lrc" | wc -l)
					downloadedalbumartcount=$(find "$downloaddir" -type f -iname "folder.*" | wc -l)
					replaygaintrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
					converttrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
					echo "Downloaded: $downloadedtrackcount Tracks"
					echo "Downloaded: $downloadedlyriccount Synced Lyrics"
					echo "Downloaded: $downloadedalbumartcount Album Cover"	

					TrackCountDownloadVerification

					if [ $error = 0 ]; then

						conversion "$downloaddir"

						if [ "${ReplaygainTagging}" = TRUE ]; then
							replaygain "$downloaddir"
						else
							echo "REPLAYGAIN TAGGING DISABLED"
						fi

						ImportProcess

						NotifyLidarr

						CleanDLPath
						
						if cat "download.log" | grep "${albumid}" | read; then
							downloaded="true"
						else
							echo "Downloaded :: ${albumid} :: ${wantitalbumartistname} :: ${albumname}" >> "download.log"
						fi

					fi
				fi
			else
				echo "ERROR: Already downloaded, skipping..."
				NotifyLidarr
			fi
		fi
	fi
	echo ""
}

AlbumDL () {
	check=1
	error=0
	trackdlfallback=0
	if [ "$downloadmethod" = "album" ]; then
		if curl -s --request GET "$deezloaderurl/api/download/?url=$albumurl&quality=$dlquality" >/dev/null; then
			echo "Download Timeout: $albumtimeoutdisplay"
			echo "Downloading $tracktotal Tracks..."
			sleep $dlcheck
			let j=0
			while [[ "$check" -le 1 ]]; do
				let j++
				if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
					check=2
				else
					sleep 1s
					if [ "$j" = "$albumtimeout" ]; then
						dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
						if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
							echo "Error downloading $albumname ($dlquality), retrying...via track method "
							trackdlfallback=1
							error=1
						fi
					fi
				fi
			done
			if find "$downloaddir" -iname "*.flac" | read; then
				fallbackqualitytext="FLAC"
			elif find "$downloaddir" -iname "*.mp3" | read; then
				fallbackqualitytext="MP3"
			fi
			if [ $error = 0 ]; then
				echo "Downloaded Album: $albumname (Format: $fallbackqualitytext; Length: $albumdurationdisplay)"
				Verify
			fi
		else
			echo "Error sending download to Deezloader-Remix (Attempt 1)"
			trackdlfallback=1
		fi
	else
		trackdlfallback=1
	fi
}

TrackDL () {
	check=1
	error=0
	retry=0
	fallback=0
	fallbackbackup=0
	fallbackquality="$dlquality"
	if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$dlquality" >/dev/null; then
		sleep $dlcheck
		let j=0
		while [[ "$check" -le 1 ]]; do
			let j++
			if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
				check=2
			else
				sleep 1
				retry=0
				if [ "$j" = "$tracktimeout" ]; then
					dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
					if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
						echo "Error downloading track $tracknumber: $trackname ($dlquality), retrying...download"
						retry=1
						find "$downloaddir" -type f -iname "*.flac" -newer "$temptrackfile" -delete
						find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
					fi
				fi
			fi
		done
	else
	    echo "Error sending download to Deezloader-Remix (Attempt 2)"
	fi
	if [ $retry = 1 ]; then
		if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$dlquality" >/dev/null; then
			sleep $dlcheck
			let k=0
			while [[ "$retry" -le 1 ]]; do
				let k++
				if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
					retry=2
				else
					sleep 1
					fallback=0
					if [ "$k" = "$trackfallbacktimout" ]; then
						dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
						if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
							echo "Error downloading track $tracknumber: $trackname ($dlquality), retrying...as mp3 320"
							fallback=1
							find "$downloaddir" -type f -iname "*.flac" -newer "$temptrackfile" -delete
							find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
						fi
					fi
				fi
			done
		else
			echo "Error sending download to Deezloader-Remix (Attempt 3)"
		fi
	fi
	if [ $fallback = 1 ]; then
		if [ "$enablefallback" = true ]; then
			if [ "$dlquality" = flac ]; then
				fallbackquality="320"
				bitrate="320"
			elif [ "$dlquality" = 320 ]; then
				fallbackquality="128"
				bitrate="128"
			fi
			if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$fallbackquality" >/dev/null; then
				sleep $dlcheck
				let l=0
				while [[ "$fallback" -le 1 ]]; do
					let l++
					if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
						fallback=2
					else
						sleep 1
						if [ "$l" = $tracktimeout ]; then
							dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
							if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
								if [ "$fallbackquality" = 128 ]; then
									echo "Error downloading track $tracknumber: $trackname (mp3 128), skipping..."
									error=1
								else
									echo "Error downloading track $tracknumber: $trackname (mp3 320), retrying...as mp3 128"
									fallbackbackup=1
								fi
								find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
							fi
						fi
					fi
				done
			else
				echo "Error sending download to Deezloader-Remix (Attempt 4)"
			fi
		else
			echo "Error downloading track $tracknumber: $trackname ($dlquality), skipping..."
			error=1
		fi
	fi
	if [ $fallbackbackup = 1 ]; then
		if [ "$enablefallback" = true ]; then
			fallbackquality="128"
			bitrate="128"
			if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$fallbackquality" >/dev/null; then
				sleep $dlcheck
				let l=0
				while [[ "$fallbackbackup" -le 1 ]]; do
					let l++
					if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
						fallbackbackup=2
					else
						sleep 1
						if [ "$l" = $trackfallbacktimout ]; then
							dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
							if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
								echo "Error downloading track $tracknumber: $trackname (mp3 128), skipping..."
								error=1
								find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
							fi
						fi
					fi
				done
			else
				echo "Error sending download to Deezloader-Remix (Attempt 5)"
			fi
		else
			echo "Error downloading track $tracknumber: $trackname ($dlquality), skipping..."
			error=1
		fi
	fi

	if find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" | read; then
		fallbackqualitytext="FLAC"
	elif find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" | read; then
		fallbackqualitytext="MP3"
	fi
	
	if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|mp3\)" -newer "$temptrackfile" | read; then
		echo "Download Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
		Verify
	else
		error=1
	fi
}

TrackMethod () {
	CleanDLPath
	sleep 0.1
	echo "Downloading $tracktotal Tracks..."
	temptrackfile="${downloaddir}/temp-track"
	trackid=($(echo "${albuminfo}" | jq -r ".tracks | .data | .[] | .id"))
	for track in ${!trackid[@]}; do
		tracknumber=$(( $track + 1 ))
		trackname=$(echo "${albuminfo}" | jq -r ".tracks | .data | .[] | select(.id=="${trackid[$track]}") | .title")
		trackduration=$(echo "${albuminfo}" | jq -r ".tracks | .data | .[] | select(.id=="${trackid[$track]}") | .duration")
		trackdurationdisplay=$(DurationCalc $trackduration)
		trackurl="https://www.deezer.com/track/${trackid[$track]}"
		tracktimeout=$(($trackduration*$tracktimeoutpercentage/100))
		trackfallbacktimout=$(($tracktimeout*2))
		if [[ "$tracktimeout" -le 60 ]]; then
			tracktimeout="60"
			trackfallbacktimout=$(($tracktimeout*2))
		fi
		if [ -f "$temptrackfile" ]; then
			rm "$temptrackfile"
			sleep 0.1
		fi
		touch "$temptrackfile"
		TrackDL
		if [ -f "$temptrackfile" ]; then
			rm "$temptrackfile"
			sleep 0.1
		fi
	done
}

ImportProcess () {
	if [ ! -d "${LidarrImportLocation}/${importalbumfolder}" ]; then
		mkdir -p "${LidarrImportLocation}/${importalbumfolder}"
		for file in "$downloaddir"/*; do
			mv "$file" "${LidarrImportLocation}/${importalbumfolder}"/
		done

		FolderAccessPermissions "${LidarrImportLocation}/${importalbumfolder}"
		FileAccessPermissions "${LidarrImportLocation}/${importalbumfolder}"
	fi
}

NotifyLidarr () {
	if [ -d "${LidarrImportLocation}/${importalbumfolder}" ]; then
		echo "Notified Lidarr to scan \"${LidarrImportLocation}/${importalbumfolder}\" for import"
		LidarrProcessIt=$(curl -s "$LidarrUrl/api/v1/command" --header "X-Api-Key:"${LidarrApiKey} --data "{\"name\":\"DownloadedAlbumsScan\", \"path\":\"${LidarrImportLocation}/${importalbumfolder}\"}" );
	fi
}

Verify () {
	if [ $trackdlfallback = 0 ]; then
		if find "$downloaddir" -iname "*.flac" | read; then
			if ! [ -x "$(command -v flac)" ]; then
				echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
			else
				for fname in "${downloaddir}"/*.flac; do
					filename="$(basename "$fname")"
					if flac -t --totally-silent "$fname"; then
						echo "Verified Track: $filename"
					else
						echo "Track Verification Error: \"$filename\" deleted...retrying download via track method"
						rm -rf "$downloaddir"/*
						sleep 0.1
						trackdlfallback=1
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
						echo "Verified Track: $filename"
					fi
				done
			fi
		fi
	elif [ $trackdlfallback = 1 ]; then
		if ! [ -x "$(command -v flac)" ]; then
			echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
		else
			if find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" | read; then
				find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" -print0 | while IFS= read -r -d '' file; do
					filename="$(basename "$file")"
					if flac -t --totally-silent "$file"; then
						echo "Verified Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
					else
						rm "$file"
						if [ "$enablefallback" = true ]; then
							echo "Track Verification Error: \"$trackname\" deleted...retrying as MP3"
							origdlquality="$dlquality"
							dlquality="320"
							TrackDL
							dlquality="$origdlquality"
						else
							echo "Verification Error: \"$trackname\" deleted..."
							echo "Fallback quality disabled, skipping..."
							error=1
						fi
					fi
				done
			fi
		fi
		if ! [ -x "$(command -v mp3val)" ]; then
			echo "MP3VAL verification utility not installed (ubuntu: apt-get install -y mp3val)"
		else
			if find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" | read; then
				find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" -print0 | while IFS= read -r -d '' file; do
					filename="$(basename "$file")"
					if mp3val -f -nb "$file" > /dev/null; then
						echo "Verified Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
					fi
				done
			fi
		fi
	fi
}

conversion () {
	converttrackcount=$(find  "$1"/ -name "*.flac" | wc -l)
	targetformat="$quality"
	bitrate="$ConversionBitrate"
	if [ "${quality}" = OPUS ]; then
		options="-acodec libopus -ab ${bitrate}k -application audio"
		extension="opus"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = AAC ]; then
		options="-acodec aac -ab ${bitrate}k -movflags faststart"
		extension="m4a"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = MP3 ]; then
		options="-acodec libmp3lame -ab ${bitrate}k"
		extension="mp3"
		targetbitrate="${bitrate}k"
	fi
	if [ "${quality}" = ALAC ]; then
		options="-acodec alac -movflags faststart"
		extension="m4a"
		targetbitrate="lossless"
	fi
	if [ "${quality}" != FLAC ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "$1"/ -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${targetbitrate}))"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn $options "${fname%.flac}.temp.$extension"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.temp.$extension" ]; then
							rm "$fname"
							sleep 0.1
							mv "${fname%.flac}.temp.$extension" "${fname%.flac}.$extension"
						fi
					else
						echo "Conversion failed: $filename, performing cleanup..."
						rm -rf "$1"/*
						sleep 0.1
						exit 1
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
		find "$1" -iname "*.flac" -exec metaflac --add-replay-gain "{}" + && echo "Replaygain: $replaygaintrackcount Tracks Tagged"
	fi
}

DLAlbumArtwork () {
	if curl -sL --fail "${albumartworkurl}" -o "$downloaddir/folder.jpg"; then
		sleep 0.1
	else
		echo "Failed downloading album cover picture..."
	fi
}

TrackCountVerification () {
	if [ "$VerifyTrackCount" = true ]; then
		if [ "$tracktotal" -ne "$actualtracktotal" ]; then
			echo "ERROR: Listed Track Count does not match actual track count"
			error=1
		fi
	fi
}

TrackCountDownloadVerification () {
	if [ "$VerifyTrackCount" = true ]; then
		if [ "$tracktotal" -ne "$downloadedtrackcount" ]; then
			echo "ERROR: Downloaded Track Count ($downloadedtrackcount) and Album Track Count ($tracktotal) do not match, skipping and performing cleanup..."
			CleanDLPath
			error=1
		fi
	fi
}

paths

LidarrAlbums

configuration

CleanDLPath

CleanImportPath

ProcessLidarrAlbums

CleanDLPath

#####################################################################################################
#                                              Script End                                           #
#####################################################################################################
exit 0
