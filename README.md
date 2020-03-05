
# lidarr-automated-downloader (LAD) Information
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
| `LidarrUrl` | Set domain or IP to your Lidarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `LidarrApiKey` | Lidarr API key |
| `deezloaderurl` | Url to the download client |
| `downloadmethod` | SET TO: album or track :: album method will fallback to track method if it runs into an issue |
| `enablefallback` | true = enabled :: enables fallback to lower quality if required... |
| `VerifyTrackCount` | true = enabled :: This will verify album track count vs dl track count, if tracks are found missing, it will skip import... |
| `dlcheck` | Set the number to desired wait time before checking for completed downloads (if your connection is unstable, longer may be better) |
| `albumtimeoutpercentage` | Set the number between 1 and 100 :: This number is used to caculate album download timeout length by multiplying Album Length by ##% |
| `tracktimeoutpercentage` | Set the number between 1 and 100 :: This number is used to caculate  track download timeout length by multiplying Track Length by ##% |
| `amount` | Maximum: 1000000000 :: Number of missing/cutoff albums to look for... |
| `quality` | SET TO: FLAC or MP3 or OPUS or AAC or ALAC |
| `ConversionBitrate` | FLAC -> OPUS/AAC will be converted using this bitrate |
| `ReplaygainTagging` | TRUE = ENABLED :: adds replaygain tags for compatible players (FLAC ONLY) |
| `FolderPermissions` | Based on chmod linux permissions |
| `FilePermissions` | Based on chmod linux permissions |
| `DownLoadArtistArtwork` | true = enabled :: Uses Lidarr Artist artwork first with a fallback using LAD as the source |

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

# Official Docker: [lidarr-lad](https://github.com/RandomNinjaAtk/docker-lidarr-lad)
* Pre-configured, no setup required, includes Lidarr

