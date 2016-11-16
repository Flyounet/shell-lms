#!/usr/bin/env bash
# /*------------------------------------------------------------------------*\
# |                                                                          |
# |                WTFPL & DSSL apply on this material.                      |
# |                                                                          |
# +--------------------------------------------------------------------------+
# |                                                                          |
# | test-shell-lms.sh : A Shell library to test the shell-lms.sh library     |
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

ls -la /proc/$$/fd/
[[ -f "$(p="$(command -v ${0})"; cd "${p%/*}/.." ; unset p; pwd)/shell-lms.sh" ]] || { echo "Can't find library shell-lms.sh. Aborting." >&2; exit 1; }
. "$(p="$(command -v ${0})"; cd "${p%/*}/.." ; unset p; pwd)/shell-lms.sh"

oth_msg_debug_plus <<< "Checking verbosity" | oth_2stderr
echo "Verbo = $( oth_verbosity_get )"
SLMS_VERBOSITY=1
echo "Verbo = $( oth_verbosity_get )"
oth_verbosity_set 9
echo "Verbo = $( oth_verbosity_get )"

SLMS_SERVER="lms.l"
SLMS_PORT=9090

# ls -la /proc/$$/fd/42

oth_msg_debug_plus <<< "CONNECT" | oth_2stderr
server_connect
oth_msg_debug_plus <<< "IS_CONNECT" | oth_2stderr
server_is_connected
_lrc=$?
[[ ${_lrc} -eq 0 ]] && echo "connected"
[[ ${_lrc} -eq 0 ]] || echo "not connected"
export SLMS_USER=toto
export SLMS_PASSWORD=tata
oth_msg_debug_plus <<< "LOGIN" | oth_2stderr
server_login

oth_msg_debug_plus <<< "GETTING PLAYERS INFOS" | oth_2stderr
export SLMS_PLAYERS_STR="$(declare -p SLMS_PLAYERS)"
oth_msg_debug_plus <<< "GETTING PLAYERS INFOS" | oth_2stderr
server_refresh
oth_msg_debug_plus <<< "PRINTING PLAYERS INFOS" | oth_2stderr
eval ${SLMS_PLAYERS_STR}
for i in $(sort <<< "${!SLMS_PLAYERS[@]}"); do
	echo "SLMS_PLAYERS[${i}]='${SLMS_PLAYERS[$i]}'"
done

oth_msg_debug_plus <<< "SEND_RAW (VALID)" | oth_2stderr
server_send_raw_datas "player count ?"
oth_msg_debug_plus <<< "READ_RAW" | oth_2stderr
server_read_raw_datas
oth_msg_debug_plus <<< "SEND_RAW (INVALID)" | oth_2stderr
server_send_raw_datas "player%20count%20%3F"
oth_msg_debug_plus <<< "READ_RAW" | oth_2stderr
server_read_raw_datas
oth_msg_debug_plus <<< "QUERY WITH ERROR" | oth_2stderr
server_query "  palyer count ? " ; echo "rc=${?}"
oth_msg_debug_plus <<< "QUERY CORRECT" | oth_2stderr
server_query "player count ?" ; echo "rc=${?}"
oth_msg_debug_plus <<< "QUERY INCORRECT" | oth_2stderr
server_query "player id 0" ; echo "rc=${?}"
oth_msg_debug_plus <<< "QUERY OK" | oth_2stderr
server_query "player id 0 ?" ; echo "rc=${?}"
oth_msg_debug_plus <<< "QUERY WITH INVALID ID" | oth_2stderr
server_query "player id 3615 ?" ; echo "rc=${?}"

oth_msg_debug_plus <<< "QUERY WITH LINES ?" | oth_2stderr
server_query "00%3A04%3A20%3A2a%3A57%3A37 status ?"
server_query "00%3A04%3A20%3A2a%3A57%3A37 status "

oth_msg_debug_plus <<< "DISCONNECT" | oth_2stderr
server_disconnect
_lrc=$?
[[ ${_lrc} -eq 0 ]] && echo "disconnected"
[[ ${_lrc} -eq 0 ]] || echo "not disconnected"
oth_msg_debug_plus <<< "IS_CONNECT" | oth_2stderr
server_is_connected
_lrc=$?
[[ ${_lrc} -eq 0 ]] && echo "connected"
[[ ${_lrc} -eq 0 ]] || echo "not connected"


oth_msg_debug_plus <<< "NOT CONNECTED : VERSION" | oth_2stderr
server_get_version
oth_msg_debug_plus <<< "CONNECTED : VERSION" | oth_2stderr
server_connect
server_get_version

oth_msg_debug_plus <<< "CONNECTED : Rescan" | oth_2stderr
server_rescan "playlists"
oth_msg_debug_plus <<< "CONNECTED : Rescanprogress" | oth_2stderr
server_rescanprogress


exit ${RC:=0} # Default return code is 0 true



