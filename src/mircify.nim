## DLL to be used with mIRC and obtain Spotify status without needing to access
## the API.
##
## See below the procedures that mircify.dll has and how to use them.
##
## This DLL is inspired by `spoton.dll<https://github.com/turbosmurfen/spoton>`_.
import std/strutils

import pkg/mdlldk

import ./mircify/api

const
  versionMajor = 1
  versionMinor = 0
  versionPatch = 0
  stringVersion = "$1.$2.$3" % [$versionMajor, $versionMinor, $versionPatch]
  dllAuthor = "rockcavera"
  dllPage = "https://github.com/rockcavera/nim-mircify"
  dllInfoText = "echo -ea mircify $1 by $2 - Made with mdlldk on Nim - $3" % [stringVersion, dllAuthor, dllPage]

addLoadProc(true, false):
  ## The dll remains loaded after being called and communication will be through
  ## ANSI strings.
  discard

addUnloadProc(RKeepLoaded):
  ## The dll will try to stay loaded even if mIRC tries to unload it after 10
  ## minutes of non-use.
  discard

newProcToExport(status):
  ## Returns the current state of Spotify, which could be:
  ## - `0` if Spotify is not running.
  ## - `1` if Spotify is running but not playing song (paused).
  ## - `2` if Spotify is running and playing advertisement.
  ## - `3` if Spotify is running and playing song.
  ##
  ## Usage: `$dll(mircify.dll, status, $null)`
  result.outData = $status()
  result.ret = RReturn

newProcToExport(song):
  ## Returns the song currently playing on Spotify. Will return an empty if
  ## Spotify is not running, paused or playing advertising.
  ##
  ## Usage: `$dll(mircify.dll, song, $null)`
  result.outData = song()
  result.ret = RReturn

newProcToExport(artist):
  ## Returns the artist of the song currently playing on Spotify. Will return an
  ## empty if Spotify is not running, paused, playing advertising or if there is
  ## no `" - "`.
  ##
  ## Usage: `$dll(mircify.dll, artist, $null)`
  result.outData = songArtist()
  result.ret = RReturn

newProcToExport(title):
  ## Returns the title of the song currently playing on Spotify. Will return an
  ## empty if Spotify is not running, paused, playing advertising or if there is
  ## no `" - "`.
  ##
  ## Usage: `$dll(mircify.dll, title, $null)`
  result.outData = songTitle()
  result.ret = RReturn

newProcToExport(control):
  ## Spotify media controls.
  ##
  ## Usage: `/dll mircify.dll control <cmd>`
  ##
  ## `<cmd>` can be:
  ## - `playpause` play or pause playback
  ## - `play` play track
  ## - `pause` pause track
  ## - `next` go to next track
  ## - `previous` go to previous track
  control(data)
  result.ret = RContinue

newProcToExport(dllInfo):
  ## Prints dll information in the active window.
  ##
  ## Usage: `/dll mircify.dll dllInfo`
  result.outdata = dllInfoText
  result.ret = RCommand

newProcToExport(version):
  ## Returns the dll version.
  ##
  ## Usage: `$dll(mircify.dll, version, $null)`
  result.outdata = stringVersion
  result.ret = RReturn

exportAllProcs()
