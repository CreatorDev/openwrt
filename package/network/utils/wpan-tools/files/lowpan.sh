#!/bin/sh
# netifd script for configuring 6lowpan interfaces
##

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/system.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	. /lib/functions/mac.sh
	init_proto "$@"
}

proto_lowpan_setup() {
	local cfg="$1" #wpan.

	local ip6addr pan_id channel ifname
	json_get_vars ip6addr pan_id channel ifname

	local id=${ifname##*[[:alpha:]]}
	local interface="$cfg$id" # i.e wpan0

	ifconfig "$interface" down
	proto_init_update "$ifname" 1

	local LOWPAN_MAC=$(get_lowpan_mac)

	# Compute EUI from MAC
	if [ ! -z "$LOWPAN_MAC" ]
	then
		local WPAN_EUI=$(echo $LOWPAN_MAC | cut -d: -f1,2,3):ff:fe:$(echo $LOWPAN_MAC | cut -d: -f4,5,6)
		ip link set $interface address $WPAN_EUI
	fi

	iwpan dev "$interface" set pan_id "$pan_id"
	iwpan phy phy$id set channel 0 $channel
	ifconfig "$interface" up

	ip link add link "$interface" name "$ifname" type lowpan

	proto_add_ipv6_address "$ip6addr" "128"
	proto_send_update "$cfg"
}

proto_lowpan_teardown() {
	local cfg="$1"
	local iface="$2"

	local ifname
	json_get_var ifname ifname

	local id=${ifname##*[[:alpha:]]}
	local interface="$cfg$id" # i.e wpan0

	ifconfig "$interface" down
	ip link del "$ifname"

	proto_kill_command "$cfg"
}

proto_lowpan_init_config() {
	no_device=1
	available=1
	proto_config_add_string "ip6addr"
	proto_config_add_string "pan_id"
	proto_config_add_string "channel"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol lowpan
}
