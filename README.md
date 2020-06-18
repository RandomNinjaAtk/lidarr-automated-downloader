
# lidarr-automated-downloader (LAD)

## Features
* Complete automation for downloading Music Audio & Video files
* Downloading **Music** using online sources and importing them into Lidarr Automatically
  * Support for Lossless downloads
  * Support for output to a perferred format (FLAC / OPUS / MP3 / AAC / ALAC)
  * Beets tagging support for improved metadata
  * Replaygain tagging for lossless FLAC files
  * Download Artist Artwork
  * Downloads Synced Lyrics for use with Plex/Kodi
  * Support for automatic imports into Lidarr
* Downloading **Music Videos** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Support for IMVDb (https://imvdb.com) to find videos
  * Support for Musicbrainz Database (https://musicbrainz.org) to find videos
  * Downloads using Highest available quality for both audio and video
  * Saves thumbnail of video locally for Plex/Kodi/Jellyfin/Emby usage
  * Writes metadata into Kodi/Jellyfin/Emby compliant NFO file
* Cron support, create a cron job to automatically run script at desired interval
* Official Docker with everything built in! [lidarr-lad](https://github.com/RandomNinjaAtk/docker-lidarr-lad)

### Audio + Video (Plex Example)
![](https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/images/plex-musicvideos.png)


## Additional Information
Visit the wiki: https://github.com/RandomNinjaAtk/lidarr-automated-downloader/wiki (more info coming soon)

## Requirements
Linux Software Packages: <br/>
* jq
* find
* ffmpeg
* beets
* flac
* mp3val
* curl
* eyed3
* kid3-cli
* youtube-dl (Video DL Client)
* deemix (Audio DL Client)<br/>

Baseline OS used for testing is Ubuntu 18.04, so use equivalent package versions

## Setup
1. Edit "config" with a text editor that can write in Unix line endings... see: [Configuration](https://github.com/RandomNinjaAtk/lidarr-automated-downloader#configuration)

## Eecution
Execute script via CLI with the following command: `bash lidarr-automated-downloader.bash`

## Files
* lidarr-automated-downloader.bash
  * script to execute
* config
  * File contains all configuration settings, see: [Configuration](https://github.com/RandomNinjaAtk/lidarr-automated-downloader#configuration)
* notfound.log
  * Log file containing list of albums that could not be found using normal or fuzzy matching, automatically cleared every Saturday via cron
* musicbrainzerror.log
  * Log file containing list of artists without links, open log for more details
* download.log
  * Log file containing list of albums that were downloaded, automatically cleared every Saturday via cron

## Configuration

Modify the "config" file to set your configuration settings using a text editor that can write in Unix line endings...

| Setting | Function |
| --- | --- |
| `downloaddir` |  Deezloader download directory location |
| `LidarrImportLocation` | Temporary location that completed downloads are moved to before lidarr attempts to match and import |
| `PathToDLClient` | Path to DL client directory (deemix) |
| `BeetConfig` | Location of beets configuration file |
| `BeetLibrary` | Location of beets library file, this file is self-cleaned after every download |
| `LidarrUrl` | Set domain or IP to your Lidarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `LidarrApiKey` | Lidarr API key |
| `DownloadMode` | Both or Audio or Video :: "Both" downloads audio and videos; "Audio" downlods only audio files; "Video" only downloads video files |
| `AudioMode` | wanted or archive :: wanted mode processes Lidarr Wanted/Cutoff Album lists (TrackUpgrade must be enabled for Cutoff) :: archive mode downloads all albums for an aritst, no lidarr matching is used for importing, keeps everything... <strong>WARNING:</strong> When using <strong>archive mode</strong> deleting/clearing the download.log will cause downloads be re-processed |
| `ImportMode` | match or forced or manual :: "match" uses lidarr's matching engine to import; "forced" moves the download into the Lidarr artist directory; "manual" downloads are left in the temp import directory for you to manual import |
| `TrackUpgrade` | true = Enabled :: Upgrades existing tracks to requested format. "wanted" mode is controlled by cutoff album list and "archive" mode is detected automatically. Recommend disabling for archive mode, unless your changing your format. |
| `python` | command to execute python 3 applications/scripts (for ubuntu, use: python3) |
| `VerifyTrackCount` | true = enabled :: This will verify album track count vs dl track count, if tracks are found missing, it will skip import... |
| `amount` | Maximum: 1000000000 :: Number of missing/cutoff albums to look for... |
| `quality` | SET TO: FLAC or MP3 or OPUS or AAC or FDK-AAC or ALAC |
| `ConversionBitrate` | FLAC -> OPUS/AAC/FDK-AAC will be converted using this bitrate |
| `ReplaygainTagging` | TRUE = ENABLED :: adds replaygain tags for compatible players (FLAC ONLY) |
| `FolderPermissions` | Based on chmod linux permissions |
| `FilePermissions` | Based on chmod linux permissions |
| `DownLoadArtistArtwork` | true = enabled :: Uses Lidarr Artist artwork first with a fallback using LAD as the source |
| `TagWithBeets` | true = enabled :: enable beet tagging to improve matching accuracy, requires beets installation and beets file path configuration |
| `RequireBeetsMatch` | true = enabled :: skips importing files that could not be matched using beets |
| `RequireQuality` | true = enabled :: skips importing files that do not match quality settings |
| `VideoPath` |  Location of music videos |
| `YoutubeDL` |  Path to youtube-dl application, executed using python |
| `musicbrainzurl` |  Change to use different musicbrainz mirror... |
| `ratelimit` |  musicbrainz rate limit, musicbrainz allows only 1 connection per second, max setting is 10 |

# Lidarr Configuration Recommendations

## Media Management Settings:
* Disable Track Naming
  * Disabling track renaming enables synced lyrics that are imported as extras to be utilized by media players that support using them

#### Track Naming:

* Artist Folder: `{Artist Name}{ (Artist Disambiguation)}`
* Album Folder: `{Artist Name}{ - ALBUM TYPE}{ - Release Year} - {Album Title}{ ( Album Disambiguation)}`

#### Importing:
* Enable Import Extra Files
  * `lrc,jpg,png`

#### File Management
* Change File Date: Album Release Date
 
#### Permissions
* Enable Set Permissions

## Connect Settings

 ### Add Custom Script
* Settings -> Connect -> + Add -> custom Script

| Parameter | Value |
| --- | --- |
| Name | Album Artwork Extractor |
| On Grab | No |
| On Release Import | Yes |
| On Upgrade | Yes |
| On Download Failure | No |
| On Import Failure | No |
| On Rename | Yes |
| On Track Retag | Yes |
| On Health Issue | No |
| Tags | leave blank |
| Path | `/path/to/artwork.bash` |

This script will extract the embedded file artwork and store it in the local ablum folder

# Official Docker: [lidarr-lad](https://github.com/RandomNinjaAtk/docker-lidarr-lad)
* Pre-configured, no setup required, includes Lidarr

