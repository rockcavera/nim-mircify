from std/strutils import find
from std/private/ospaths2 import extractFilename

from pkg/winim/inc/psapi import GetProcessImageFileNameA
from pkg/winim/inc/windef import DWORD, HANDLE, HWND, LPARAM, LPCSTR, LPDWORD,
                                 LPSTR, LPWSTR, LRESULT, UINT, WINBOOL, WPARAM,
                                 FALSE, MAX_PATH, PROCESS_QUERY_INFORMATION,
                                 PROCESS_QUERY_LIMITED_INFORMATION
from pkg/winim/inc/winbase import CloseHandle, OpenProcess
from pkg/winim/inc/winuser import FindWindowExA, GetClassNameA,
                                  GetWindowTextA, GetWindowTextLengthA,
                                  GetWindowTextLengthW, GetWindowTextW,
                                  GetWindowThreadProcessId, IsWindow,
                                  IsWindowUnicode, SendMessageA,
                                  APPCOMMAND_MEDIA_NEXTTRACK,
                                  APPCOMMAND_MEDIA_PAUSE, APPCOMMAND_MEDIA_PLAY,
                                  APPCOMMAND_MEDIA_PLAY_PAUSE,
                                  APPCOMMAND_MEDIA_PREVIOUSTRACK,
                                  APPCOMMAND_MEDIA_REWIND, WM_APPCOMMAND
from pkg/winim/winstr import `$`, newWString, setLen,
                             winstrConverterWStringToLPWSTR,
                             winstrConverterStringToPtrChar

const
  invalidHWND = HWND(0)
    ## Invalid `HWND`
  invalidPId = DWORD(0)
    ## Invalid Process Identifier
  maxlpszClassName = 256
    ## Maximum length for lpszClassName.
    # https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-wndclassexa
  spotifyClassName = "Chrome_WidgetWin_1"
    ## Spotify window class name.
  spotifyExe = "Spotify.exe"
    ## Name of the Spotify executable.

var
  spotifyHwnd: HWND = invalidHWND
    ## Stores the `HWND` of the Spotify window.
  spotifyPId: DWORD = invalidPId
    ## Stores Spotify process identifier (PID).

proc getPid(hwnd: HWND): DWORD {.noinit.} =
  ## Returns the identifier of the process that created the window `hwnd`.
  result = invalidPId
  discard GetWindowThreadProcessId(hwnd, addr result)

proc getClassName(hwnd: HWND): string =
  ## Returns a `string` with the class name of the window `hwnd`.
  result = newString(maxlpszClassName - 1)
  let len = GetClassNameA(hwnd, result, maxlpszClassName)
  setLen(result, len)

proc getFilename*(pid: DWORD): string =
  ## Returns a `string` with the name of the file referring to `pid`.
  var
    dwDesiredAccess: DWORD = PROCESS_QUERY_INFORMATION
    attempts = 1

  while attempts < 3:
    let hProcess = OpenProcess(dwDesiredAccess, FALSE, pid)

    if hProcess != 0:
      var path = newString(MAX_PATH)
      let len = GetProcessImageFileNameA(hProcess, path, MAX_PATH)
      setLen(path, len)
      result = extractFilename(path)
      discard CloseHandle(hProcess)
      break

    dwDesiredAccess = PROCESS_QUERY_LIMITED_INFORMATION # not supported on Windows Server 2003 and
                                                        # Windows XP, but necessary to
                                                        # `OpenProcess()` for elevated process
                                                        # called by normal process
    inc(attempts)

proc getWindowText(hwnd: HWND): string =
  ## Returns a `string` with the text present in the title bar of the Spotify
  ## window.
  if IsWindowUnicode(hwnd) != FALSE:
    let lenbuff = GetWindowTextLengthW(hwnd)
    var text = newWString(lenbuff)
    let len = GetWindowTextW(hwnd, text, lenbuff + 1)
    setLen(text, len)
    result = $text
  else:
    let lenbuff = GetWindowTextLengthA(hwnd)
    result = newString(lenbuff)
    let len = GetWindowTextA(hwnd, result, lenbuff + 1)
    setLen(result, len)

proc spotifyHwndAndPid(): tuple[hwnd: HWND, pid: DWORD] {.noinit.} =
  ## Returns a `tuple[hwnd: HWND, pid: DWORD]`, where `hwnd` is the Spotify
  ## window handle and `pid` is the Spotify process identifier.
  result = (invalidHWND, invalidPId)

  var hwnd = 0

  while true:
    hwnd = FindWindowExA(0, hwnd, spotifyClassName, nil)

    if hwnd == 0:
      break

    let pid = getPid(hwnd)

    if getFileName(pid) == spotifyExe:
      return (hwnd, pid)

proc initmircify(): bool =
  ## Initializes mircify and returns `true` if Spotify is running. If Spotify is
  ## not running, returns `false`.
  (spotifyHwnd, spotifyPId) = spotifyHwndAndPid()
  spotifyHwnd != invalidHWND and spotifyPId != invalidPId

proc isSpotifyRunning(): bool =
  ## Returns `true` if Spotify is running. If Spotify is not running, returns
  ## `false`.
  if spotifyHwnd == invalidHWND or spotifyPId == invalidPId:
    result = initmircify()
  elif IsWindow(spotifyHwnd) != FALSE and getPid(spotifyHwnd) == spotifyPId and
     getClassName(spotifyHwnd) == spotifyClassName and
     getFilename(spotifyPId) == spotifyExe:
    result = true
  else:
    result = initmircify()

proc spotify(): tuple[status: int, song: string] =
  ## Returns a `tuple[status: int, song: string]`, where `status` refers to the
  ## Spotify state and `song` the song currently playing (if any).
  ##
  ## `status` could be:
  ## - `0` if Spotify is not running.
  ## - `1` if Spotify is running but not playing song (paused).
  ## - `2` if Spotify is running and playing advertisement.
  ## - `3` if Spotify is running and playing song.
  ##
  ## `song` will only not be `""` (empty) when `status == 3`.
  if isSpotifyRunning():
    let text = getWindowText(spotifyHwnd)

    case text
    of "Spotify Premium", "Spotify Free":
      result.status = 1
    of "Advertisement":
      result.status = 2
    else:
      result.status = 3
      result.song = text

proc status*(): int =
  ## Returns the current state of Spotify, which could be:
  ## - `0` if Spotify is not running.
  ## - `1` if Spotify is running but not playing song (paused).
  ## - `2` if Spotify is running and playing advertisement.
  ## - `3` if Spotify is running and playing song.
  spotify().status

proc song*(): string =
  ## Returns the song currently playing on Spotify. Will return an empty
  ## `string` (`""`) if Spotify is not running, paused or playing advertising.
  (_, result) = spotify()

proc songArtist*(): string =
  ## Returns the artist of the song currently playing on Spotify. Will return an
  ## empty `string` (`""`) if Spotify is not running, paused, playing
  ## advertising or if there is no `" - "`.
  let (status, song) = spotify()

  if status == 3:
    let i = find(song, " - ")

    if i != -1:
      result = song[0..(i - 1)]

proc songTitle*(): string =
  ## Returns the title of the song currently playing on Spotify. Will return an
  ## empty `string` (`""`) if Spotify is not running, paused, playing
  ## advertising or if there is no `" - "`.
  let (status, song) = spotify()

  if status == 3:
    let i = find(song, " - ")

    if i != -1:
      result = song[(i + 3)..^1]

template sendAppCommandMedia(appCommand: static[LPARAM]) =
  ## Template for SendMessage to send application command, where `appCommand` is
  ## the `APPCOMMAND`
  discard SendMessageA(spotifyHwnd, WM_APPCOMMAND, 0, appCommand shl 16)

proc control*(cmd: string) =
  ## media controls, where `cmd` can be:
  ## - `"playpause"` play or pause playback
  ## - `"play"` play track
  ## - `"pause"` pause track
  ## - `"next"` go to next track
  ## - `"previous"` go to previous track
  if isSpotifyRunning():
    case cmd
    of "playpause":
      sendAppCommandMedia(APPCOMMAND_MEDIA_PLAY_PAUSE)
    of "play":
      sendAppCommandMedia(APPCOMMAND_MEDIA_PLAY)
    of "pause":
      sendAppCommandMedia(APPCOMMAND_MEDIA_PAUSE)
    of "next":
      sendAppCommandMedia(APPCOMMAND_MEDIA_NEXTTRACK)
    of "previous":
      sendAppCommandMedia(APPCOMMAND_MEDIA_PREVIOUSTRACK)
      sendAppCommandMedia(APPCOMMAND_MEDIA_PREVIOUSTRACK)
    else:
      discard
