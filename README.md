
# SLMS (Shell LMS) Library

The Logitech Media Server (LMS) is a perl developped `server to _stream_ your collection of music to players.  
This Bash oriented library intends to provide a full `support of the API of LMS servers.

Many years before Sonos, Logitech produced a pretty good product, but, unfortunately, stopped it. The LMS software has, since, been released under free software and is still developped.

## How to use this Library ?

Just load the library in your shell script, it's as simple as :

    # Load the SLMS library in the libs/ subdir
    . "$(p="$(command -v ${0})"; cd "${p%/*}/libs" ; unset p; pwd)/shell-lms.sh"

Then you could start to use it. Have a look in the `helpers/test-shell-lms.sh` script.

