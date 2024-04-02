# Package

version       = "1.0.0"
author        = "rockcavera"
description   = "DLL to be used with mIRC and obtain Spotify status without needing to access the API"
license       = "MIT"
srcDir        = "src"
bin           = @["mircify"]


# Dependencies

requires "nim >= 2.1.1", "mdlldk >= 0.2.0", "winim >= 3.9.2"
