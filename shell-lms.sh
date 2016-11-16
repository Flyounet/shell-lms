#!/usr/bin/env bash
# [*------------------DON'T-TOUCH-THE-FOLLOWING-LINE------------------------*]
[[ -z "${BASH_VERSION}" || ${BASH_VERSINFO[0]:-0} -lt 4 ]] && { printf -- "Bash 4 minimum is required. Aborting."; exit 1; }
# [*-----------------UNLESS-YOU-KNOW-WHAT-YOU'RE DOING----------------------*]


# /*------------------------------------------------------------------------*\
# |                                                                          |
# |                WTFPL & DSSL apply on this material.                      |
# |                                                                          |
# +--------------------------------------------------------------------------+
# |                                                                          |
# | shell-lms.sh : A Shell library to manage LMS : Logitech Media Server     |
# | Copyright (C) 2016 Flyounet — Tous droits réservés.                      |
# |                                                                          |
# | Cette œuvre est distribuée SANS AUCUNE GARANTIE hormis celle d'être      |
# | distribuée sous les termes de la Licence Demerdez-vous («Demerden Sie    |
# | Sich License») telle que publiée par Flyounet : soit la version 1 de     |
# | cette licence,soit (à votre gré) toute version ultérieure.               |
# | telle que publiée par Flyounet : soit la version 1 de cette licence,     |
# | soit (à votre gré) toute version ultérieure.                             |
# |                                                                          |
# | Vous devriez avoir reçu une copie de la Licence Démerdez-vous avec cette |
# | œuvre ; si ce n’est pas le cas, consultez :                              |
# | <http://dssl.flyounet.net/licenses/>.                                    |
# |                                                                          |
# \*------------------------------------------------------------------------*/

# All variables will be prefixed by SLMS_
# Only 4 Global Variables in upper Case

export SLMS_SERVER=""
export SLMS_PORT=9090
export SLMS_USER=""
export SLMS_PASSWORD=""

# Could go to 9
export SLMS_VERBOSITY=${SMLS_VERBOSITY:=0}

# Autres variables
# slms_server_ for all server informations
# slms_clients_ for all clients informations
# slms_client_ for A client informations

# Most of the functions must write to sdout the results
# functions will be prefixed also
# server_ for function related to server
# client_ for function related to client (even if we must go through the server)
# oth_ for other functions (mainly internal)

# Feature +
# Autodiscover exec 4<> /dev/udp/255.255.255.255/3483
# tcpdump le premier qui répond 3483 -> 3483...

# Print sur 2> les messages verbose login ok
# 

# /*------------------------------------------------------------------------*\
# |                                                                          |
# | oth_* functions : Not directly related to server or player               |
# |                                                                          |
# \*------------------------------------------------------------------------*/

#
# oth_2stderr : Send message to stderr
#
oth_2stderr() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	printf -- "${_datas//%/%%}\n" >&2
}

#
# oth_msg_* : print a colored message
#
oth_msg_ok() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	printf -- "\e[32m${_datas//%/%%}\e[0m"; # Green
}
oth_msg_info() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	printf -- "\e[34m${_datas//%/%%}\e[0m"; # Blue
}
oth_msg_warning() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	printf -- "\e[33m${_datas//%/%%}\e[0m"; # Yellow
}
oth_msg_error() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	printf -- "\e[31m${_datas//%/%%}\e[0m"; # Red
}
oth_msg_debug() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
#	printf -- "\e[2m${_datas//%/%%}\e[22m"; # Diminued
	printf -- "\e[36m${_datas//%/%%}\e[0m"; # Diminued
}
oth_msg_debug_plus() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
#	printf -- "\e[2m${_datas//%/%%}\e[22m"; # Diminued
	printf -- "\e[93m${_datas//%/%%}\e[0m"; # Diminued
}
#
# oth_verbosity : Print to stderr if VERBOSITY requested. Use stdin for message.
# And $1 for the verbosity level.
# /!\ We suppose $1 is a number : no check on it
#
oth_verbosity() {
	[[ ${SLMS_VERBOSITY:=0} -eq 0 ]] && return 0
	[[ ${SLMS_VERBOSITY} -ge ${1} ]] && oth_2stderr <<< "$(date '+%FT%TZ') - $(cat)"
}

#
# oth_verbosity_get : Return SLMS_VERBOSITY
#
oth_verbosity_get() {
	echo ${SLMS_VERBOSITY:=0}
}

#
# oth_verbosity_set : Set the SLMS_VERBOSITY variable
#
oth_verbosity_set() {
	[[ ! -z "${1:-}" && -z "${1//[0-9]/}" && ${1} -ge 0 && ${1} -le 9 ]] || { oth_msg_error <<< "Can't set SLMS_VERBOSITY to '${1}'. Must be a number between 0 and 9." | oth_2stderr; return 1; }
	export SLMS_VERBOSITY=${1}
	oth_msg_ok <<< "SLMS_VERBOSITY updated to '${1}'" | oth_verbosity 2
	return 0
}

#
# oth_check_binaries : Check if binaries are available
#
oth_check_binaries() {
	local cmdErr="sed awk date iconv cat getent ss readlink"
	for _cmd in ${cmdErr}; do
                if ! command -v "${_cmd}" &>/dev/null; then
                        oth_msg_error <<< "command not found: ${_cmd}" | oth_2stderr
                        local _rc=1 # false
                fi
        done
	unset cmdErr ; unset _cmd
	return ${_rc:=0}; # Default 0 : true
}

#
# oth_host_to_ip : try to get the ip of a host (if host is an ip, ip returned).
#
oth_host_to_ip() {
	grep -qE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' <<< "${1:-}" && { printf -- "${1}"; return 0; }
	getent hosts "${1}" | awk '{print $1}'
}

#
# oth_encode_datas :
# 
oth_encode_datas() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	old_lc_collate="${LC_COLLATE}"; LC_COLLATE=C
	local length="${#_datas}"
	for (( i = 0; i < length; i++ )); do
		local c="${_datas:i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf "$c" ;;
			*) printf '%%%02X' "'$c" ;;
		esac
	done
	LC_COLLATE="${old_lc_collate}"
	unset _datas ; unset old_lc_collate ; unset length ; unset c
}

#
# oth_decode_datas : 
# /!\ Don't forget to decode twice filename (or URL)
#
oth_decode_datas() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	local url_encoded="${_datas//+/ }"
	printf '%b' "${url_encoded//%/\\x}"
	unset _datas ; unset url_encode
}

#
# oth_trim_datas : Remove space from start/end string 
#
oth_trim_datas() {
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	sed -e 's;^[[:space:]]*\([^[:space:]].*[^[:space:]]\)[[:space:]]*$;\1;g' <<< "${_datas}"
	unset _datas
}

oth_is_cache_valid() {
	oth_msg_info <<< "Checking if cache is still valid..." | oth_verbosity 1
	(( $(date "+%s") - ${SLMS_CACHE_TTL:=300} > ${SLMS_CACHE_LAST:=0} )) && export SLMS_CACHE_REVALIDATE=true;
	[[ ${SLMS_CACHE_REVALIDATE:=false} = true || ${SLMS_NO_CACHE:=false} = true ]] && return 1
	oth_msg_debug <<< "Cache is valid" | oth_verbosity 3
	return 0
}
# oth_txt_encode
# oth_txt_decode
# Following is an example of encode/decode datas
#server_encode_datas "ba:ba:da:da:00:01"
#echo ''
#server_decode_datas "ba%3Aba%3Ada%3Ada%3A00%3A01"
#echo ''
#server_decode_datas "ba%3Aba%3Ada%3Ada%3A00%3A01 playlist path 11 file%3A%2F%2F%2Fvolume1%2Fm_Music%2Fm_Dance-Electonic%2FMinistry%2520of%2520Sound%2520Collection%2FMinistry%2520of%2520Sound%2520-%2520Ibiza%2520Annual%25202013%2FCD1%2F(08)%2520%5BTi%25C3%25ABsto%2520Feat.%2520Kyler%2520England%5D%2520Take%2520Me.mp3"
#echo ''
#server_decode_datas "$(server_decode_datas "ba%3Aba%3Ada%3Ada%3A00%3A01 playlist path 11 file%3A%2F%2F%2Fvolume1%2Fm_Music%2Fm_Dance-Electonic%2FMinistry%2520of%2520Sound%2520Collection%2FMinistry%2520of%2520Sound%2520-%2520Ibiza%2520Annual%25202013%2FCD1%2F(08)%2520%5BTi%25C3%25ABsto%2520Feat.%2520Kyler%2520England%5D%2520Take%2520Me.mp3")"
#echo ''


#sed -rn '/((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])/p'
# server_connect
# server_disconnect
# server_refresh
# clients_id
# client_uuid_get
# client_name_get
# client_name_set

# /*------------------------------------------------------------------------*\
# |                                                                          |
# | server_* functions : Functions related to the LMS server                 |
# |                                                                          |
# \*------------------------------------------------------------------------*/

#
# server_is_connected : Check if the socket to server is open
#
server_is_connected() {
	oth_msg_info <<< "Checking if server connected..." | oth_verbosity 1
	[[ ! -e /proc/$$/fd/42 ]] && { oth_msg_debug <<< "Socket /proc/$$/fd/42 doesn't exists" | oth_verbosity 3; return 1; }
	[[ ! -S /proc/$$/fd/42 ]] && { oth_msg_error <<< "/proc/$$/fd/42 exists but it's not a socket." | oth_2stderr; exit 1; }
	local _link="$( readlink /proc/$$/fd/42 )"
	local _sck=''
	while read _sck; do
		[[ "${_link//\[$_sck\]/}" != "${_link}" ]] && { oth_msg_debug "Connected to ${SLMS_SERVER}:${SLMS_PORT}" | oth_verbosity 3 ; return 0; }
	done <<< "$( ss -t4e state established dport = $(oth_host_to_ip "${SLMS_SERVER}"):${SLMS_PORT} | sed -e '/ino:/!d;s/^.*ino:\([0-9]\{1,\}\)[^0-9].*$/\1/g' )"
	unset _sck ; unset _link
	oth_msg_debug "Not connected to ${SLMS_SERVER}:${SLMS_PORT}" | oth_verbosity 3
	return 1
}

#
# server_connect : 
#
server_connect() {
	oth_msg_info <<< "Connecting to server..." | oth_verbosity 1
	server_is_connected && server_disconnect;
#	exec 4<>/dev/tcp/$( oth_host_to_ip "${SLMS_SERVER}" )/${SLMS_PORT}
	exec 42<>/dev/tcp/${SLMS_SERVER}/${SLMS_PORT}
	if [ ${?} -eq 0 ]; then
		local _RC=0
		oth_msg_ok <<< "Connection OK" | oth_verbosity 2
	else
		local _RC=1
		oth_msg_error <<< "Connecting NOK" | oth_verbosity 2
	fi
# changer le trap pour appeler server_disconnect
	return ${_RC}
}

#
# server_disconnect : 
#
server_disconnect() {
	oth_msg_info <<< "Disconnecting from server..." | oth_verbosity 1
	server_is_connected && {
		exec 42<&-
		exec 42>&-
		oth_msg_ok <<< "Disconnection OK" | oth_verbosity 2
	}
	oth_msg_info <<< "Connexion closed" | oth_verbosity 2
}

#
# server_connect_if_disconnected : Connect to the server if needed
#
server_connect_if_disconnected() {
	oth_msg_info <<< "Checking server connection..." | oth_verbosity 1
	server_is_connected || server_connect
	return ${?}
}

#
# server_send_raw_datas : Datas are not encoded. Do it before send them to server
#
server_send_raw_datas() {
	oth_msg_info <<< "Sending datas to server..." | oth_verbosity 1
	local _datas="${@:-}"
	[[ -z "${_datas}" ]] && _datas="$(cat)"
	oth_msg_debug "Writing '${_datas}'" | oth_verbosity 3
	printf -- "${_datas//%/%%}\n" >&42
	local _rc=${?}
	[[ ${_rc} -eq 0 ]] && oth_msg_ok <<< "Datas sent..." | oth_verbosity 1
	[[ ${_rc} -ne 0 ]] && oth_msg_warning <<< "Unable to send datas..." | oth_2stderr
	unset _datas
	return ${_rc}
}

#
# server_read_raw_datas : Read datas. To be sure the read ends, we only wait for SLMS_WAITTHINKTIME
#
server_read_raw_datas() {
	oth_msg_info <<< "Reading datas from server..." | oth_verbosity 1
	local _str=''
	while read -t ${SLMS_WAITTHINKTIME:=0.5} -u 42 _str; do [[ ! -z "${_str}" ]] && { echo "${_str}" >&1; oth_msg_debug "Reading '${_str}'" | oth_verbosity 3; }; done
	local _rc=${?}
	[[ ${_rc} -eq 0 ]] && oth_msg_ok <<< "Datas read..." | oth_verbosity 1
	[[ ${_rc} -ne 0 ]] && oth_msg_warning <<< "Unable to read datas..." | oth_2stderr
	unset _str
	return ${_rc}
}

#
#
#
# Query avec un ? à la fin qui devient %3F en réponse d'une erreur
# Query question sans ?
# query action la réponse est la question

server_action() {
	# Execute et n'attend rien en retour que la requete qu'il a fait
	sleep 1
}
server_question() {
	# Ask for information with a question mark
	# answer with %3F if invalid question
	sleep 1
}
server_query() {
	oth_msg_info <<< "Querying server..." | oth_verbosity 1
	local _query="${@:-}"
	[[ -z "${_query}" ]] && _query="$(cat)"
	[[ -z "${_query}" ]] && { oth_msg_error <<< "Query is empty." | oth_2stderr; return 1; }
	_query="$( oth_trim_datas "${_query}" )"
	local _s=$(( ${#_query} - 1)); local _queryB="${_query:0:$_s}"
	local _queryE="${_query: -1}"
	oth_msg_debug <<< "Query is '${_query}'" | oth_verbosity 3
	server_send_raw_datas "${_query}" || return 1
	local _datas="$(server_read_raw_datas)"
	oth_msg_debug <<< "Datas collected are '${_datas}'" | oth_verbosity 3
	oth_msg_debug_plus "Query     : '${_query}'" | oth_verbosity 4
	oth_msg_debug_plus "Query Deb : '${_queryB}' (_s=${_s})" | oth_verbosity 4
	oth_msg_debug_plus "Query Fin : '${_queryE}'" | oth_verbosity 4
	oth_msg_debug_plus "Query Alt : '${_queryB}$(oth_encode_datas "${_queryE}")'" | oth_verbosity 4
	oth_msg_debug_plus "Resultats : '${_datas}'" | oth_verbosity 4
# si ? et query + encoded ?= data
#set -xv
	if [ "${_queryE}" = "?" -o "${_queryE}" = "%3F" -o "${_query}" = "${_datas}" ]; then
		[[ "${_datas}" = "${_queryB}$(oth_encode_datas "${_queryE}")" ]] && { oth_msg_error <<< "Incorrect request" | oth_2stderr; return 1; }
#set -xv
		sed -e "s;^[[:space:]]*${_queryB}[[:space:]]*\([^[:space:]].*\)[[:space:]]*$;\1;g" <<< "${_datas}"
set +xv
	else
		[[ "${_query}" = "${_datas}" || "${_query}" = "${_datas}?" ]] && { oth_msg_warning <<< "Incorrect request" | oth_2stderr; return 1; }
#set -xv
		sed -e "s;^[[:space:]]*${_query}[[:space:]]*\([^[:space:]].*\)[[:space:]]*$;\1;g" <<< "${_datas}"
set +xv
	fi
#	if [ "$( oth_trim_datas "${_query}" | oth_encode_datas )" = "$( oth_trim_datas "${_datas}" )" -o "$( oth_trim_datas "${_query}" )" = "$( oth_trim_datas "${_datas}" )" ]; then
set +xv
#		oth_msg_error <<< "Request was not correct." | oth_2stderr; return 1;
#	else
#		sed -e "s;^[[:space:]]*${_query}[[:space:]]*\([^[:space:]].*[^[:space:]]\)[[:space:]]*$;\1;g" <<< "${_datas}"
set +xv
#	fi
	oth_msg_ok "We could eventualy think everything went OK for your request" | oth_2stderr
	unset _query ; unset _datas ; unset _s ; unset _queryE ; unset _queryB
	return 0
}

#
# server_login : Send credentials to server to authenticate the session
#
server_login() {
	oth_msg_info <<< "Sending credentials to server..." | oth_verbosity 1
	[[ -z "${SLMS_USER:=}" ]] && { oth_msg_error <<< "User is empty." | oth_2stderr; exit 1; }
	[[ -z "${SLMS_PASSWORD:=}" ]] && { oth_msg_error <<< "Password is empty." | oth_2stderr; exit 1; }
	local _cmd="login "
	server_send_raw_datas "${_cmd} $(oth_encode_datas "${SLMS_USER}") $(oth_encode_datas "${SLMS_PASSWORD}")" || return 1;
	local _datas="$(server_read_raw_datas)"
	[[ "${_datas}" = "${_cmd} $(oth_encode_datas "${SLMS_USER}") ******" ]] && local _rc=0;
	[[ ${_rc:=1} -eq 0 ]] && oth_msg_ok <<< "You're logged in..." | oth_verbosity 1
	unset _cmd ; unset _datas
	return ${_rc}
}

#
#
#
server_refresh() {
	oth_msg_info <<< "Refreshing Players infos if needed..." | oth_verbosity 1
	server_connect_if_disconnected || { oth_msg_error <<< "Unable to reconnect." | oth_2stderr; exit 1; }
	server_login || { oth_msg_error <<< "Unable to authenticate." | oth_2stderr; exit 1; }
#	(( $(date "+%s") - ${_CACHE_TTL:=300} > ${_CACHE_LAST:=0} )) && export _CACHE_REVALIDATE=true;
##	if [ ${_CACHE_REVALIDATE:=false} = true -o (( $(date "+%s" - ${_CACHE_TTL:=300} > ${_CACHE_LAST:=0} )) ]; then
#	if [ ${_PLAYERS:=0} -eq 0 -o ${_CACHE_REVALIDATE} = true -o ${_NO_CACHE:=false} = true ]; then
	if ! oth_is_cache_valid; then
		export _PLAYERS=$(server_get_player_count)
		[[ ${?} -ne 0 ]] && { oth_msg_error "Unable to retrieve number of player." | oth_2stderr; return 1; }
		for (( i=0 ; i<${_PLAYERS} ; i++ )); do
			server_get_player_basics ${i}
		done
		export SLMS_PLAYERS_STR
		export SLMS_CACHE_LAST=$(date '+%s')
	fi
	return 0
}
server_get_player_basics() {
	oth_msg_info <<< "Getting all infos for player ${1}..." | oth_verbosity 1
	eval "${SLMS_PLAYERS_STR}"
	[[ ${1:-0} -lt 0 || ${1} -ge ${_PLAYERS} ]] && { oth_msg_warning "Not a valid Player ID" | oth_2stderr; return 1; }
	SLMS_PLAYERS[${1}_id]="$(player_get_id "${1}")"
	SLMS_PLAYERS[${1}_uuid]="$(player_get_uuid "${1}")"
	SLMS_PLAYERS[${1}_name]="$(player_get_name "${1}")"
	SLMS_PLAYERS[${1}_ip]="$(player_get_ip "${1}")"
	SLMS_PLAYERS[${1}_model]="$(player_get_model "${1}")"
	SLMS_PLAYERS[${1}_display_type]="$(player_get_displaytype "${1}")"
	SLMS_PLAYERS[${1}_can_power_off]="$(player_get_canpoweroff "${1}")"
	SLMS_PLAYERS[${1}_is_player]="$(player_get_isplayer "${1}")"
	SLMS_PLAYERS[${1}_is_connected]="$(player_get_isconnected "$( oth_encode_datas "${SLMS_PLAYERS[${1}_id]}" )")"
	export SLMS_PLAYERS_STR="$(declare -p SLMS_PLAYERS)"
}

#
# server_get_player_count : Return the numer of player (probably connected)
# SLMS_CACHE durée
# SLMS_CACHE_REFRESH true/false
# _SLMS_CACHE_LAST date +%s
#
server_get_player_count() {
	oth_msg_info <<< "Retrieving number of player..." | oth_verbosity 1

}

server_get_player_list() {
	oth_msg_info <<< "Retrieving list of player..." | oth_verbosity 1

}

#
# server_is_rescan : if the server rescan is in progress return true/0
#
server_is_rescan() {
	oth_msg_info <<< "Checking server rescan status..." | oth_verbosity 1
	if [ "$(server_query "rescan ?")" = '0' -o ${?} -ne 0 ]; then
		oth_msg_debug "Rescan is stopped" | oth_verbosity 3
		return 1
	fi
	oth_msg_ok "Rescan is already in progress" | oth_verbosity 2
	return 0
}

#
# server_rescan : Check if the server rescan is running or run it if not
#
server_rescan() {
	oth_msg_info <<< "Retrieving/setting server rescan status..." | oth_verbosity 1
	server_is_rescan || {
		local _type="${1:-fast}"
		oth_msg_debug "Rescan type is '${_type}'" | oth_verbosity 3
		case "${_type,,}" in
			full) local _q="wipecache";;
			playlists) local _q="rescan playlists";;
			fast|*) local _q="rescan";;
		esac
		server_query "${_q}"
	}
	return ${?}
}

#
# server_rescanprogress : check is the rescan run and return the progress status
#
server_rescanprogress() {
	oth_msg_info <<< "Retrieving server rescan progress infos..." | oth_verbosity 1
	server_is_rescan && server_query "rescanprogress"
	return ${?}
}

#
# server_get_version : Return the version of the server
#
server_version() { server_get_version; }
server_get_version() {
	oth_msg_info <<< "Retrieving server version..." | oth_verbosity 1
	server_query "version ?"
	return ${?}
}

#
# server_get_player_count : Return the number of know player from the server
#
server_player_count() { server_get_player_count; }
server_get_player_count() {
	oth_msg_info <<< "Retrieving server rescan progress infos..." | oth_verbosity 1
	server_query "player count ?"
	return ${?}
}

# /*------------------------------------------------------------------------*\
# |                                                                          |
# | player_* functions : Functions related to LMS players                    |
# |                                                                          |
# \*------------------------------------------------------------------------*/

#
# player_get_id : Return either the cached/uncached player id
#
player_get_id() {
#set -xv
	oth_msg_info <<< "Retrieving player id..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_id]}"; return 0; }
	server_query "player id ${1} ?" | oth_decode_datas
}

#
# player_get_uuid : Return either the cached/uncached player uuid
#
player_get_uuid() {
	oth_msg_info <<< "Retrieving player uuid..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_uuid]}"; return 0; }
	server_query "player uuid ${1} ?" | oth_decode_datas
}

#
# player_get_ip : Return either the cached/uncached player ip
#
player_get_ip() {
	oth_msg_info <<< "Retrieving player ip..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_ip]}"; return 0; }
	server_query "player ip ${1} ?" | oth_decode_datas
}


#
# player_get_name : Return either the cached/uncached player name
#
player_get_name() {
	oth_msg_info <<< "Retrieving player name..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_name]}"; return 0; }
	server_query "player name ${1} ?" | oth_decode_datas
}

#
# player_set_name : Change player name
#
player_set_name() {
	oth_msg_info <<< "Changing player name..." | oth_verbosity 1
	[[ ${#} -lt 2 || -z "${2:-}" ]] && { oth_msg_error "Player name is empty" | oth_2stderr; return 1; }
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_name]}"; return 0; }
	if server_query "player name ${1} ${2}" ; then
		oth_msg_debug "From ${SLMS_PLAYERS[${1}_name]} ..." | oth_verbosity 3
		export _SLMS_PLAYERS[${1}_name]="${2}"
		oth_msg_debug "To ${SLMS_PLAYERS[${1}_name]}" | oth_verbosity 3
	fi
}


#
# player_get_model : Return either the cached/uncached player model
#
player_get_model() {
	oth_msg_info <<< "Retrieving player model..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_model]}"; return 0; }
	server_query "player model ${1} ?" | oth_decode_datas
}

#
# player_get_displaytype : Return either the cached/uncached player display_type
#
player_get_displaytype() {
	oth_msg_info <<< "Retrieving player displaytype..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_displaytype]}"; return 0; }
	server_query "player displaytype ${1} ?" | oth_decode_datas
}

#
# player_get_canpoweroff : Return either the cached/uncached player can_power_off
#
player_get_canpoweroff() {
	oth_msg_info <<< "Retrieving player canpoweroff..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_canpoweroff]}"; return 0; }
	server_query "player canpoweroff ${1} ?" | oth_decode_datas
}

#
# player_get_isplayer : Return either the cached/uncached player is_player
#
player_get_isplayer() {
	oth_msg_info <<< "Retrieving player isplayer..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_isplayer]}"; return 0; }
	server_query "player isplayer ${1} ?" | oth_decode_datas
}

#
# player_get_isconnected : Return either the cached/uncached player is_connected
#
player_get_isconnected() {
	oth_msg_info <<< "Retrieving player connected..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_model]}"; return 0; }
	server_query "${1} connected ?" | oth_decode_datas
}


#
# player_get_wifisignalstrength : Return either the cached/uncached player signalstrength
#
player_get_wifisignalstrength() {
	oth_msg_info <<< "Retrieving player signalstrength..." | oth_verbosity 1
	oth_is_cache_valid && { echo -n "${SLMS_PLAYERS[${1}_model]}"; return 0; }
	server_query "${1} signalstrength ?" | oth_decode_datas
}


####################################################################################
#                                                                                  #
# MAIN PROGAM : Loaded & executed                                                  #
#                                                                                  #
####################################################################################

oth_check_binaries || { RC=1; [[ ${SLMS_EXIT_ON_MISSING_PROGRAM:=1} -eq 1 ]] && exit 1; }

export _PLAYERS=0
declare -A SLMS_PLAYERS=()
declare -x SLMS_PLAYERS_STR="$(declare -p SLMS_PLAYERS)"
declare -a SMLS_DATAS

# Faire un check pour être sûr qu'on est loadé






#exit ${RC:=0} # Default return code is 0 true



