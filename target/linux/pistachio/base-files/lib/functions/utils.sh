#!/bin/sh
#
# Copyright (C) 2017 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#


elapsed_time() {
	local time=$1
	current_time=$(awk -F "." '{print $1}' /proc/uptime | awk '{print $1}')
	local time_elapsed=0
	time_elapsed=$(expr $current_time - $time)
	echo "$time_elapsed"
}
