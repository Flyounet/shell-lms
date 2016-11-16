
# SLMS (Shell LMS) Library

The Logitech Media Server (LMS) is a perl developped `server to _stream_ your collection of music to players.  
This Bash oriented library intends to provide a full `support of the API of LMS servers.

Many years before Sonos, Logitech has produce a pretty good product, but, unfortunately, `stopped it. The LMS software has, since, been released under free software and is still developped.

## How to use this Library ?

Just load the library in your shell script, it's as simple as :

    # Load the SLMS library in the libs/ subdir
    . "$(p="$(command -v ${0})"; cd "${p%/*}/libs" ; unset p; pwd)/shell-lms.sh"

Then you could start to use it. Have a look in the `helpers/test-shell-lms.sh` script.

## SLMS variables

 * Server variables :
    Mainly related to the configuration of your `server.
 * * `SLMS_SERVER` : The LMS Server hostname or IP.
 * * `SLMS_PORT` : The LMS Server Port.
 * * `SLMS_USER` : If you activate `security, the LMS Server user used to log on.
 * * `SLMS_PASSWORD` : _Do I really need to explain ?_ The password required for the `SLMS_USER`.
 * * `SLMS_WAITTHINKTIME` : Time in `second to wait for the server to answer a query (depending on your system to be a float).
 * Runtime variables :
    Mainly related to the usage of the SLMS library.
 * * `SLMS_VERBOSITY` : Integer needed to activate traces. Use `oth_verbosity_set` to change this variable.
 * * `SLMS_CACHE_TTL` : Time in `second (default 300) before the cache need to be refreshed.
 * * `SLMS_CACHE_REVALIDATE`  : Boolean generated to indicate what to do with the cache.
 * * `SLMS_CACHE_LAST` : Epoch time when the last cahce was refreshed.
 * * `SLMS_NO_CACHE` : Boolen to force the cache to be refreshed.
 * * `SLMS_EXIT_ON_MISSING_PROGRAM` : The Shell LMS library checks if needed binaries are existing. If any is missing, it aborts (default).
 * Players informations :
    Store your player(s) informations.
 * * `_PLAYERS` : Number of player.
 * * `SLMS_PLAYERS` : Array where are `stored each player informations. Note the datas are cached.
 * * `SLMS_PLAYERS_STR`: Array are not exportable between function. This `string is the serialized representation of `SLMS_PLAYERS`.

## SLMS functions

 * **`oth_*`** :
    Functions not directly related to players or `server.
 * * `oth_2stderr` : Send datas to `stderr
 * * `oth_msg_ok` : Enhance datas to be pretty
 * * `oth_msg_info` : Enhance datas to be pretty
 * * `oth_msg_warning` : Enhance datas to be pretty
 * * `oth_msg_error` : Enhance datas to be pretty
 * * `oth_msg_debug` : Enhance datas to be pretty
 * * `oth_msg_debug_plus` : Enhance datas to be pretty
 * * `oth_verbosity` : Print to `stderr if the verbose level is reach
 * * `oth_verbosity_get` : Get the verbose level
 * * `oth_verbosity_set` : Set the verbose level
 * * `oth_check_binaries` : Valid if binaries needed to work exits 
 * * `oth_host_to_ip` : Transform hostanme to IP
 * * `oth_encode_datas` : Encode datas
 * * `oth_decode_datas` : Decode datas
 * * `oth_trim_datas` : Remove trailling `space at begin/end.
 * * `oth_is_cache_valid` : Cehck if the cached datas are `still valid.

 * **`server_*`** :
    Functions mainly related to `server.
 * * `server_is_connected` : 
 * * `server_connect` : Connect (anyway) to the LSM Server
 * * `server_disconnect` : Disconnect from the LMS Server
 * * `server_connect_if_disconnected` : Connect to LMS server if not connected
 * * `server_send_raw_datas` : Send datas to the LMS server (not check)
 * * `server_read_raw_datas` : Read datas from server (no check)
 * * `server_action` : ???
 * * `server_question` : ???
 * * `server_query` : Send a query to the LMS server and print the result
 * * `server_login` : Send credentials to the server
 * * `server_refresh` : Refresh Players datas (if allowed by cache policy)
 * * `server_get_player_basics` : Retrieve basic information for all players
 * * `server_player_count` :  Return the number of player know by the server (starting at `0`)
 * * `server_get_player_count` : Same as above
 * * `server_get_player_list` : ???
 * * `server_is_rescan` : Return the state of the rescan process (not the status)
 * * `server_rescan` : Inform the LMS Server to do a rescan
 * * `server_rescanprogress` : Return the status of the rescan process (not the state)
 * * `server_version` : Return the version of the LMS Server 
 * * `server_get_version` : Same as above

 * **`player_*`** :
    Function related to players.
 * * `player_get_id` : Return the player MAC adress
 * * `player_get_uuid` : Return the player UUID
 * * `player_get_ip` : Return the player IP
 * * `player_get_name` : Return the player name
 * * `player_set_name` : Change the player name
 * * `player_get_model` : Return the player model
 * * `player_get_displaytype` : Return the player display type
 * * `player_get_canpoweroff` : Return the player status to know if it can be powered off
 * * `player_get_isplayer` : Return the player status to know if it a player
 * * `player_get_isconnected` : Return the player status to know if it is connected
 * * `player_get_wifisignalstrength` : Return the player wifi sgnal strength
