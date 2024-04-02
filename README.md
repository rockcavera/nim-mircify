# mircify
DLL to be used with mIRC and obtain Spotify status without needing to access the API

## Download
Download the [latest release](releases/latest)

## Procedures
List of mircify.dll procedures

### status
Returns the current state of Spotify, which could be:
- `0` if Spotify is not running.
- `1` if Spotify is running but not playing song (paused).
- `2` if Spotify is running and playing advertisement.
- `3` if Spotify is running and playing song.

Usage: `$dll(mircify.dll, status, $null)`

### song
Returns the song currently playing on Spotify. Will return an empty if Spotify is not running, paused or playing advertising.

Usage: `$dll(mircify.dll, song, $null)`

### artist
Returns the artist of the song currently playing on Spotify. Will return an empty if Spotify is not running, paused, playing advertising or if there is no `" - "`.

Usage: `$dll(mircify.dll, artist, $null)`

### title
Returns the title of the song currently playing on Spotify. Will return an empty if Spotify is not running, paused, playing advertising or if there is no `" - "`.

Usage: `$dll(mircify.dll, title, $null)`

### control
Spotify media controls.

Usage: `/dll mircify.dll control <cmd>`

`<cmd>` can be:
- `playpause` play or pause playback
- `play` play track
- `pause` pause track
- `next` go to next track
- `previous` go to previous track

### dllInfo
Prints dll information in the active window.

Usage: `/dll mircify.dll dllInfo`

### version
Returns the dll version.

Usage: `$dll(mircify.dll, version, $null)`

## Building
Dependencies:
- [Nim](https://nim-lang.org/) 2.0.0 or higher;
- C compiler (GNU GCC, LLVM Clang or Microsoft Visual C++); and
- Nimble Packages: [mdlldk](https://github.com/rockcavera/nim-mdlldk) 0.2.0 or higher; and [winim](https://github.com/khchen/winim) 3.9.2 or higher.

Clone this repository and type: `nim c --app:lib --cpu:i386 --mm:arc --noMain -d:noRes -d:useMalloc -d:danger --threads:off src/mircify`
