#!/bin/sh

# ubiquiti_adm - manage Ubiquiti Unifi access-point via SSH
# 2022, Laurent Ghigonis <ooookiwi@gmail.com>

# notes:
# persistent save of system.cfg : cfgmtd -f /tmp/system.cfg -w

usageexit() {
	cat <<-_EOF
usage: $0 [-q] <ubiquiti_host> <action>
action:
   system                : get system informations
   wifi-aps              : list wifi access points ssids
   wifi-clis             : list wifi clients per access point
   wifi-start <num|ssid> : start one ssid
   wifi-start-radio      : start wifi radio, enabling all ssids
   wifi-stop <num|ssid>  : stop one ssid
   wifi-stop-radio       : stop wifi radio, disabling all ssids
   ssh                   : open ssh session
   -v                    : verbose output
SSH_OPTS=$SSH_OPTS
_EOF
	exit 1
}
log() { [ $VERBOSE -eq 1 ] && echo "$1" >&2 || true; }
trace() { log "$ $*"; "$@"; }
err() { echo "error: $@"; exit 1; }

SSH_OPTS=${SSH_OPTS:-"-o HostKeyAlgorithms=+ssh-rsa"}

set -e

VERBOSE=0
[ "X$1" = X"-v" ] && shift && VERBOSE=1
[ $# -lt 2 ] && usageexit
host=$1
action=$2

case $action in
system)
	trace ssh $SSH_OPTS root@$host "uname -ap; uptime; grep 'unifi.version' /tmp/system.cfg; cat /etc/version"
	;;
wifi-aps)
	trace ssh -T $SSH_OPTS root@$host /bin/sh <<-_EOF
sed -n 's/^wireless\.\([0-9]*\)\.ssid=\(.*\)/\1 \2/p' /tmp/system.cfg |while read -r num ssid; do
	iface=\$(sed -n "s/^wireless\.\$num\.devname=\(.*\)/\1/p" /tmp/system.cfg)
	status=\$(ip a s dev \$iface |head -n1 |grep -q UP && echo "UP  " || echo DOWN)
	echo "\$num \$iface \$status \$ssid"
done
_EOF
	;;
wifi-clis)
	trace ssh $SSH_OPTS root@$host "mca-ctrl -t dump" \
		| jq '.vap_table[] | [.bssid, .essid, .channel, .tx_bytes, .rx_bytes, [ .sta_table[] | [ .mac, .ip, .signal, .uptime, .idletime, .tx_bytes, .rx_bytes, .hostname ] ] ]' \
		| sed ':a;N;$!ba;s/,\n/,/g' |egrep '[a-z0-9]'
	;;
wifi-scan)
	trace ssh $SSH_OPTS root@$host "iwlist ath0 scan"
	;;
wifi-start|wifi-stop)
	[ $# -ne 3 ] && usageexit
	if [ "$3" -eq "$3" ] 2>/dev/null; then
		vap_num=$3
		trace ssh $SSH_OPTS root@$host "grep -q 'wireless\.${vap_num}\.ssid=' /tmp/system.cfg" \
			|| err "access point number '$vap_num' does not exist"
	else
		ssid="$3"
		vap_num=$(trace ssh $SSH_OPTS root@$host "sed -n 's/^wireless\.\([0-9]*\)\.ssid=${ssid}$/\1/p' /tmp/system.cfg")
		[ -z "$vap_num" ] && err "ssid '$ssid' does not exist"
	fi
	iface=$(trace ssh $SSH_OPTS root@$host "sed -n 's/^wireless\.${vap_num}\.devname=\(.*\)/\1/p\' /tmp/system.cfg")
	[ $action = "wifi-start" ] \
		&& trace ssh $SSH_OPTS root@$host "ifconfig $iface up" \
		|| trace ssh $SSH_OPTS root@$host "ifconfig $iface down"
	;;
wifi-start-radio|wifi-stop-radio)
	[ "$action" = "wifi-start-radio" ] \
		&& flag="up" \
		|| flag="down"
	trace ssh $SSH_OPTS root@$host "sed -n 's/^radio\.[0-9]*\.phyname=\(.*\)/\1/p\' /tmp/system.cfg |while read phy; do ifconfig \$phy $flag; done"
	;;
ssh)
	trace ssh $SSH_OPTS root@$host
	;;
*)
	usageexit
esac

